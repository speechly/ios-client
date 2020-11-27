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
