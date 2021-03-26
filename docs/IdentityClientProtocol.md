# IdentityClientProtocol

Protocol that defines a client for Speechly Identity API.

``` swift
public protocol IdentityClientProtocol
```

## Requirements

### authenticate(appId:​deviceId:​)

Exchanges application and device identifiers for an access token to Speechly API.

``` swift
func authenticate(appId: UUID, deviceId: UUID) -> EventLoopFuture<ApiAccessToken>
```

#### Parameters

  - appId: Speechly application identifier.
  - deviceId: Device identifier.

#### Returns

A future that succeeds with an access token or fails with an error if authentication fails.

### authenticateProject(projectId:​deviceId:​)

Exchanges project and device identifiers for an access token to Speechly API.

``` swift
func authenticateProject(projectId: UUID, deviceId: UUID) -> EventLoopFuture<ApiAccessToken>
```

#### Parameters

  - projectId: Speechly project identifier. All applications in the project are accesible during connection.
  - deviceId: Device identifier.

#### Returns

A future that succeeds with an access token or fails with an error if authentication fails.
