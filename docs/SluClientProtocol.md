# SluClientProtocol

A protocol defining a client for Speechly SLU API.

``` swift
public protocol SluClientProtocol
```

It exposes functionality for starting and stopping SLU recognition streams
and a delegate for receiving the responses.

> 

## Requirements

### delegate

A delegate which is called when the client receives messages from the API or catches errors.

``` swift
var delegate: SluClientDelegate?
```

### connect(token:​config:​)

Connects to the SLU API.

``` swift
func connect(token: ApiAccessToken, config: SluConfig) -> EventLoopFuture<Void>
```

> 

#### Parameters

  - token: An auth token received from Speechly Identity API.
  - config: The configuration of the SLU stream.

#### Returns

A future which will be fullfilled when the stream has been connected.

### disconnect()

Disconnects the current connection to the SLU API.

``` swift
func disconnect() -> EventLoopFuture<Void>
```

If there is an active `Context`, it is cancelled.

#### Returns

A future which is fulfilled when the stream has been disconnected.

### startContext(appId:​)

Starts a new SLU recognition stream.

``` swift
func startContext(appId: String?) -> EventLoopFuture<Void>
```

> 

#### Parameters

  - appId: The target appId for the audio, if not set in the token.

#### Returns

A future which will be fullfilled when the stream has been started.

### stopContext()

Stops the current SLU recognition stream

``` swift
func stopContext() -> EventLoopFuture<Void>
```

#### Returns

A future which will be fullfilled when the stream has been closed from the client side.

### suspend()

Suspends the client by terminating any in-flight streams and disconnecting the channels.

``` swift
func suspend() -> EventLoopFuture<Void>
```

#### Returns

A future which will be fullfilled when the streams and channels are cleaned up.

### resume()

Resumes the client by restoring the channels and cleaning up any stale streams.

``` swift
func resume() -> EventLoopFuture<Void>
```

#### Returns

A future which will be fullfilled when the channels are restored.

### write(data:​)

Writes audio data on the current stream.

``` swift
func write(data: Data) -> EventLoopFuture<Void>
```

> 

#### Parameters

  - data: The audio data to write to the stream

#### Returns

A future which will be fullfilled when the data has been sent.
