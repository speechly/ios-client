import Foundation
import AVFoundation

// MARK: - AudioRecorder definition

/// An audio recorder implementation that uses AVFoundation audio engine for capturing the input.
///
/// The recorder uses an audio buffer and converter for dispatching data chunks
/// in the required sample rate, channel count and format.
public class AudioRecorder {
    /// Errors thrown by the audio recorder.
    public enum AudioRecorderError: Error {
        case outputFormatError
    }

    private let _sampleRate: Double
    private let _channels: UInt32

    private let hostTimeFrequency: Double
    private var stopRequestedAt: UInt64?

    private let audioQueue: DispatchQueue
    private var audioEngine: AVAudioEngine

    private let delegateQueue: DispatchQueue
    private weak var _delegate: AudioRecorderDelegate? = nil

    /// Create a new audio recorder.
    ///
    /// - Parameters:
    ///     - sampleRate: The sample rate to use for recording, in Hertz.
    ///     - channels: The amount of audio channels to capture.
    ///     - format: The audio format to use for capture (e.g. PCM16).
    ///     - audioQueue: `DispatchQueue` to use for handling audio data from the microphone.
    ///     - delegateQueue: `DispatchQueue` to use when calling delegate.
    ///     - prepareOnInit: If `true`, the recorder will prepare audio engine when initialised.
    ///                      Otherwise it will be prepared separately.
    ///
    /// - Important: This initialiser will throw IFF `prepareOnInit` is set to `true`.
    public init(
        sampleRate: Double,
        channels: UInt32,
        format: AVAudioCommonFormat = .pcmFormatInt16,
        audioQueue: DispatchQueue = DispatchQueue(label: "com.speechly.iosclient.AudioRecorder.audioQueue"),
        delegateQueue: DispatchQueue = DispatchQueue(label: "com.speechly.iosclient.AudioRecorder.delegateQueue"),
        prepareOnInit: Bool = true
    ) throws {
        guard let outputFormat = AVAudioFormat(
            commonFormat: format,
            sampleRate: sampleRate,
            channels: channels,
            interleaved: true
        ) else {
            throw AudioRecorderError.outputFormatError
        }

        var timebaseInfo = mach_timebase_info_data_t()
        if mach_timebase_info(&timebaseInfo) == KERN_SUCCESS {
            self.hostTimeFrequency = Double(timebaseInfo.denom) / Double(timebaseInfo.numer)
        } else {
            self.hostTimeFrequency = 1
        }

        self._sampleRate = sampleRate
        self._channels = channels
        self.delegateQueue = delegateQueue
        self.audioQueue = audioQueue
        self.audioEngine = AVAudioEngine()

        let inputNode = self.audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        let formatConverter = AVAudioConverter(from: inputFormat, to: outputFormat)!

        inputNode.installTap(
            onBus: 0,
            bufferSize: AVAudioFrameCount(inputFormat.sampleRate * 0.1),
            format: nil
        ) { [weak self] (buffer, time) in
            self?.audioQueue.async { [weak self] in
                guard let self = self else { return }

                let outputBuffer = AVAudioPCMBuffer(
                    pcmFormat: outputFormat,
                    frameCapacity: AVAudioFrameCount(outputFormat.sampleRate * 0.1)
                )!

                var error: NSError? = nil
                formatConverter.convert(
                    to: outputBuffer,
                    error: &error,
                    withInputFrom: { inNumPackets, outStatus in
                        outStatus.pointee = AVAudioConverterInputStatus.haveData
                        return buffer
                    }
                )

                if error != nil {
                    self.delegateQueue.async {
                        self.delegate?.audioRecorderDidCatchError(self, error: error!)
                    }

                    self.audioEngine.stop()

                    return
                }

                if let channelData = outputBuffer.int16ChannelData {
                    let channels = UnsafeBufferPointer(start: channelData, count: 1)
                    let bufferLengthInNanos = Double(NSEC_PER_SEC) * Double(outputBuffer.frameLength) / outputFormat.sampleRate
                    let endBufferTime = time.hostTime + UInt64(bufferLengthInNanos * self.hostTimeFrequency)

                    let data = Data(
                        bytes: channels[0],
                        count: Int(
                            outputBuffer.frameLength *
                            outputBuffer.format.streamDescription.pointee.mBytesPerFrame
                        )
                    )

                    self.delegateQueue.async {
                        self.delegate?.audioRecorderDidReceiveData(self, audioData: data)
                    }

                    // Check if stop has been requested, and this buffer ends after requested stop.
                    // We won't cut the buffer as we are anyway over the actual stop,
                    // so having sub 100ms accuracy in stopping is not relevant.
                    if let stopRequestedAt = self.stopRequestedAt, endBufferTime >= stopRequestedAt {
                        self.delegateQueue.async {
                            self.delegate?.audioRecorderDidStop(self)
                        }

                        self.reset()
                    }
                }
            }
        }

        if prepareOnInit {
            try self.prepareAudioSession()
        }
    }

    deinit {
        self.audioEngine.stop()
        self.audioEngine.reset()
    }

    private var isAudioSessionPrepared = false
    private func prepareAudioSession() throws {
        if self.isAudioSessionPrepared {
            return
        }

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .voiceChat)
        let enableFront = true

        if enableFront, audioSession.availableInputs?.count == 1,
            let microphone = audioSession.availableInputs?.first(where: { $0.portType == .builtInMic })
        {
            if let frontDataSource = microphone.dataSources?.first(where: { $0.orientation?.rawValue == AVAudioSession.Orientation.front.rawValue }) {
                if frontDataSource.supportedPolarPatterns?.contains(AVAudioSession.PolarPattern(rawValue: "Cardioid")) ?? false {
                    try frontDataSource.setPreferredPolarPattern(AVAudioSession.PolarPattern(rawValue: "Cardioid"))
                }

                try audioSession.setInputDataSource(frontDataSource)
            }
        }

        self.audioEngine.prepare()
        self.isAudioSessionPrepared = true
    }

    private func reset() {
        self.stopRequestedAt = nil

        self.audioEngine.pause()
        self.audioEngine.reset()
    }
}

// MARK: - AudioRecorderProtocol conformance

extension AudioRecorder: AudioRecorderProtocol {
    public var channels: UInt32 {
        return self._channels
    }

    public var sampleRate: Double {
        return self._sampleRate
    }

    public weak var delegate: AudioRecorderDelegate? {
        get {
            return self._delegate
        }

        set(newValue) {
            self.delegateQueue.sync(flags: .barrier) {
                self.reset()
                self._delegate = newValue
            }
        }
    }

    public func start() throws {
        if self.stopRequestedAt != nil {
            // Force stop previous recordings without sending the possible missing piece of buffer.
            // Should be fine as we are already in a delayed stop. But is not fully accurate
            // vs. implementing buffer slicing and dicing. This can cut the tail end of the previous
            // utterance that can be problematic, but the start of a new one is more important than
            // the tail of the previous as it is already delayed a bit.
            self.delegate?.audioRecorderDidStop(self)
            self.reset()
        }

        try self.prepareAudioSession()
        try AVAudioSession.sharedInstance().setActive(true)
        try self.audioEngine.start()
    }

    public func stop() {
        // Stop only queues a timed stop half a second from now, as having a bit of a tail has better
        // results than cutting of directly at the end of a word. Which is something users seems to do a lot.
        let halfSecondInHostNanos = UInt64(Double(NSEC_PER_SEC / 2) * self.hostTimeFrequency)
        self.stopRequestedAt = mach_absolute_time() + halfSecondInHostNanos
    }

    public func suspend() throws {
        self.audioEngine.stop()
        self.audioEngine.reset()

        try AVAudioSession.sharedInstance().setActive(false)

        self.stopRequestedAt = nil
        self.isAudioSessionPrepared = false
    }

    public func resume() throws {
        try self.prepareAudioSession()
    }
}
