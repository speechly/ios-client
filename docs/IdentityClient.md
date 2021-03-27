# IdentityClient

A client for Speechly Identity gRPC API.

``` swift
public class IdentityClient
```

Exposes functionality for authenticating identifiers in exchange for API access tokens.

## Inheritance

[`Promisable`](Promisable), [`IdentityClientProtocol`](IdentityClientProtocol)

## Nested Type Aliases

### `IdentityApiClient`

Alias for Speechly Identity client protocol.

``` swift
public typealias IdentityApiClient = Speechly_Identity_V2_IdentityAPIClientProtocol
```

## Initializers

### `init(addr:loopGroup:)`

Creates a new client.

``` swift
public convenience init(addr: String, loopGroup: EventLoopGroup) throws
```

#### Parameters

  - addr: The address of Speechly Identity API service.
  - loopGroup: `NIO.EventLoopGroup` to use for the client.

### `init(group:client:)`

Creates a new client.

``` swift
public init(group: EventLoopGroup, client: IdentityApiClient)
```

#### Parameters

  - loopGroup: `NIO.EventLoopGroup` to use for the client.
  - client: `IdentityApiClient` implementation.

## Methods

### `makeFailedFuture(_:)`

``` swift
public func makeFailedFuture<T>(_ error: Error) -> EventLoopFuture<T>
```

### `makeSucceededFuture(_:)`

``` swift
public func makeSucceededFuture<AuthToken>(_ value: AuthToken) -> EventLoopFuture<AuthToken>
```

### `authenticate(appId:deviceId:)`

``` swift
public func authenticate(appId: UUID, deviceId: UUID) -> EventLoopFuture<ApiAccessToken>
```

### `authenticateProject(projectId:deviceId:)`

``` swift
public func authenticateProject(projectId: UUID, deviceId: UUID) -> EventLoopFuture<ApiAccessToken>
```
