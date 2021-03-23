# CachingIdentityClient

A client for Speechly Identity gRPC API which provides token caching functionality.

``` swift
public class CachingIdentityClient
```

The cache is implemented as read-through and transparent for the consumer.

## Inheritance

[`IdentityClientProtocol`](IdentityClientProtocol)

## Nested Type Aliases

### `PromisableClient`

The protocol constraints for backing base Identity client.

``` swift
public typealias PromisableClient = IdentityClientProtocol & Promisable
```

## Initializers

### `init(baseClient:cache:)`

Creates a new client.

``` swift
public init(baseClient: PromisableClient, cache: CacheProtocol)
```

#### Parameters

  - baseClient: A base Identity client to use for fetching tokens.
  - cache: A cache to use for storing tokens.

## Methods

### `authenticate(appId:deviceId:)`

``` swift
public func authenticate(appId: UUID, deviceId: UUID) -> EventLoopFuture<ApiAccessToken>
```

### `authenticateProject(projectId:deviceId:)`

``` swift
public func authenticateProject(projectId: UUID, deviceId: UUID) -> EventLoopFuture<ApiAccessToken>
```
