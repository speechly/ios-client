# AudioRecorderProtocol

A protocol for capturing audio data from input sources (microphones).

``` swift
public protocol AudioRecorderProtocol
```

An audio recorder is supposed to capture audio data from a microphone
with a pre-configured sample rate and channel count.
It should also provide the functionality for starting and stopping the capture as well as
preparing the recorder and resetting it to default state

The data, errors and events should be dispatched to the delegate.

## Requirements

### delegate

The delegate that will receive the data, errors and events from the recorder.

``` swift
var delegate: AudioRecorderDelegate?
```

### sampleRate

The sample rate used for recording.

``` swift
var sampleRate: Double
```

### channels

The amount of channels captured by the recorder.

``` swift
var channels: UInt32
```

### start()

Starts the recorder.

``` swift
func start() throws
```

> 

### stop()

Starts the recorder.

``` swift
func stop()
```

> 

### suspend()

Suspends the recorder, telling it to release any resources.

``` swift
func suspend() throws
```

### resume()

Resumes the recorder, re-initialising any resources needed for audio capture.

``` swift
func resume() throws
```
