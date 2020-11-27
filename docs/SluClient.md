# SluClient

An SluClientProtocol that is implemented on top of public Speechly SLU gRPC API.
Uses `swift-grpc` for handling gRPC streams and connectivity.

``` swift
public class SluClient
```

## Inheritance

[`SluClientProtocol`](SluClientProtocol)

## Nested Type Aliases

### `SluApiClient`

An alias for Speechly SLU client protocol.

``` swift
public typealias SluApiClient = Speechly_Slu_V1_SLUClientProtocol
```

## Initializers

### `init(addr:loopGroup:delegateQueue:)`

Creates a new client.

``` swift
public convenience init(addr: String, loopGroup: EventLoopGroup, delegateQueue: DispatchQueue = DispatchQueue(label: "com.speechly.iosclient.SluClient.delegateQueue")) throws
```

#### Parameters

  - addr: The address of Speechly SLU API to connect to.
  - loopGroup: The `NIO.EventLoopGroup` to use in the client.
  - delegateQueue: The `DispatchQueue` to use for calling the delegate.

### `init(client:group:delegateQueue:)`

Creates a new client.

``` swift
public init(client: SluApiClient, group: EventLoopGroup, delegateQueue: DispatchQueue)
```

#### Parameters

  - client: The `SluApiClient` to use for creating SLU streams.
  - group: The `NIO.EventLoopGroup` to use in the client.
  - delegateQueue: The `DispatchQueue` to use for calling the delegate.

## Properties

### `delegate`

``` swift
var delegate: SluClientDelegate?
```

## Methods

### `start(token:config:)`

``` swift
public func start(token: ApiAccessToken, config: SluConfig) -> EventLoopFuture<Void>
```

### `stop()`

``` swift
public func stop() -> EventLoopFuture<Void>
```

### `resume()`

``` swift
public func resume() -> EventLoopFuture<Void>
```

### `suspend()`

``` swift
public func suspend() -> EventLoopFuture<Void>
```

### `write(data:)`

``` swift
public func write(data: Data) -> EventLoopFuture<Bool>
```
