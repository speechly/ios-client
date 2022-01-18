import Foundation

// MARK: - AudioRecorderProtocol definition.

/// A protocol for capturing audio data from input sources (microphones).
///
/// An audio recorder is supposed to capture audio data from a microphone
/// with a pre-configured sample rate and channel count.
/// It should also provide the functionality for starting and stopping the capture as well as
/// preparing the recorder and resetting it to default state
///
/// The data, errors and events should be dispatched to the delegate.
public protocol AudioRecorderProtocol {
    /// The delegate that will receive the data, errors and events from the recorder.
    var delegate: AudioRecorderDelegate? { get set }

    /// The sample rate used for recording.
    var sampleRate: Double { get }

    /// The amount of channels captured by the recorder.
    var channels: UInt32 { get }

    /// Starts the recorder.
    ///
    /// - Important: It MUST be valid to start a non-prepared recorder.
    ///   In that case the recorder should prepare itself on the first start.
    ///   Also, it should be possible to call `start` consecutively multiple times.
    ///   The semantics of such behavior are decided by the implementation.
    func start() throws

    /// Starts the recorder.
    ///
    /// - Important: It should be possible to call `stop` consecutively multiple times.
    ///   The semantics of such behavior are decided by the implementation.
    func stop()

    /// Suspends the recorder, telling it to release any resources.
    func suspend() throws

    /// Resumes the recorder, re-initialising any resources needed for audio capture.
    func resume() throws
}

// MARK: - AudioRecorderDelegate definition.

/// Delegate called when audio recorder receives some data or an error, or when it has been stopped.
public protocol AudioRecorderDelegate: AnyObject {
    /// Called when the recorder catches an error.
    ///
    /// - Parameter error: The error which was caught.
    func audioRecorderDidCatchError(_ audioRecorder: AudioRecorderProtocol, error: Error)

    /// Called after the recorder has received some audio data.
    ///
    /// - Parameter audioData: The data chunk received from the input.
    func audioRecorderDidReceiveData(_ audioRecorder: AudioRecorderProtocol, audioData: Data)

    /// Called after the recorder has stopped recording.
    func audioRecorderDidStop(_ audioRecorder: AudioRecorderProtocol)
}

// MARK: - AudioRecorderDelegate default implementation.

public extension AudioRecorderDelegate {
    func audioRecorderDidReceiveData(_ audioRecorder: AudioRecorderProtocol, audioData: Data) {}
    func audioRecorderDidCatchError(_ audioRecorder: AudioRecorderProtocol, error: Error) {}
    func audioRecorderDidStop(_ audioRecorder: AudioRecorderProtocol) {}
}
