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

### start(token:​config:​)

Starts a new SLU recognition stream.

``` swift
func start(token: ApiAccessToken, config: SluConfig) -> EventLoopFuture<Void>
```

> 

#### Parameters

  - token: An auth token received from Speechly Identity API.
  - config: The configuration of the SLU stream.

#### Returns

A future which will be fullfilled when the stream has been started.

### stop()

Stops the current SLU recognition stream

``` swift
func stop() -> EventLoopFuture<Void>
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
func write(data: Data) -> EventLoopFuture<Bool>
```

> 

#### Parameters

  - data: The audio data to write to the stream

#### Returns

A future which will be fullfilled when the data has been sent.
