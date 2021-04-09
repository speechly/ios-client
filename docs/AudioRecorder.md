# AudioRecorder

An audio recorder implementation that uses AVFoundation audio engine for capturing the input.

``` swift
public class AudioRecorder
```

The recorder uses an audio buffer and converter for dispatching data chunks
in the required sample rate, channel count and format.

## Inheritance

[`AudioRecorderProtocol`](AudioRecorderProtocol.md)

## Initializers

### `init(sampleRate:channels:format:audioQueue:delegateQueue:prepareOnInit:)`

Create a new audio recorder.

``` swift
public init(sampleRate: Double, channels: UInt32, format: AVAudioCommonFormat = .pcmFormatInt16, audioQueue: DispatchQueue = DispatchQueue(label: "com.speechly.iosclient.AudioRecorder.audioQueue"), delegateQueue: DispatchQueue = DispatchQueue(label: "com.speechly.iosclient.AudioRecorder.delegateQueue"), prepareOnInit: Bool = true) throws
```

> 

#### Parameters

  - sampleRate: The sample rate to use for recording, in Hertz.
  - channels: The amount of audio channels to capture.
  - format: The audio format to use for capture (e.g. PCM16).
  - audioQueue: `DispatchQueue` to use for handling audio data from the microphone.
  - delegateQueue: `DispatchQueue` to use when calling delegate.
  - prepareOnInit: If `true`, the recorder will prepare audio engine when initialised. Otherwise it will be prepared separately.

## Properties

### `channels`

``` swift
var channels: UInt32
```

### `sampleRate`

``` swift
var sampleRate: Double
```

### `delegate`

``` swift
var delegate: AudioRecorderDelegate?
```

## Methods

### `start()`

``` swift
public func start() throws
```

### `stop()`

``` swift
public func stop()
```

### `suspend()`

``` swift
public func suspend() throws
```

### `resume()`

``` swift
public func resume() throws
```
