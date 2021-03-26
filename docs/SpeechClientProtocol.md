# SpeechClientProtocol

A speech client protocol.

``` swift
public protocol SpeechClientProtocol
```

The purpose of a speech client is to abstract away the handling of audio recording and API streaming,
providing the user with a high-level abstraction over the microphone speech recognition.

## Requirements

### delegate

A delegate which is called when the client has received and parsed messages from the API.
The delegate will also be called when the client catches an error.

``` swift
var delegate: SpeechClientDelegate?
```

### start(appId:​)

Start a new recognition context and unmute the microphone.

``` swift
func start(appId: String?)
```

> 

#### Parameters

  - appId: Define a specific Speechly appId to send the audio to. Not needed if the appId can be inferred from login.

### stop()

Stop current recognition context and mute the microphone.

``` swift
func stop()
```

> 

### suspend()

Suspend the client, releasing any resources and cleaning up any pending contexts.

``` swift
func suspend()
```

This method should be used when your application is about to enter background state.

### resume()

Resume the client, re-initialing necessary resources to continue the operation.

``` swift
func resume() throws
```

This method should be used when your application is about to leave background state.
