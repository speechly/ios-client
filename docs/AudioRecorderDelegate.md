# AudioRecorderDelegate

Delegate called when audio recorder receives some data or an error, or when it has been stopped.

``` swift
public protocol AudioRecorderDelegate: class
```

## Inheritance

`class`

## Requirements

### audioRecorderDidCatchError(\_:​error:​)

Called when the recorder catches an error.

``` swift
func audioRecorderDidCatchError(_ audioRecorder: AudioRecorderProtocol, error: Error)
```

#### Parameters

  - error: The error which was caught.

### audioRecorderDidReceiveData(\_:​audioData:​)

Called after the recorder has received some audio data.

``` swift
func audioRecorderDidReceiveData(_ audioRecorder: AudioRecorderProtocol, audioData: Data)
```

#### Parameters

  - audioData: The data chunk received from the input.

### audioRecorderDidStop(\_:​)

Called after the recorder has stopped recording.

``` swift
func audioRecorderDidStop(_ audioRecorder: AudioRecorderProtocol)
```
