# ApiAccessToken

A struct representing an access token returned by Speechly Identity service.

``` swift
public struct ApiAccessToken: Hashable
```

The token is required for other application-specific Speechly APIs like Speechly SLU API.

## Inheritance

`Hashable`

## Initializers

### `init?(tokenString:)`

Creates a new token from a raw token representation, returned by Identity API.

``` swift
public init?(tokenString: String)
```

> 

#### Parameters

  - tokenString: raw token value obtained from Identity API or cache.

### `init(appId:deviceId:expiresAt:scopes:tokenString:)`

Creates a new token.

``` swift
public init(appId: UUID, deviceId: UUID, expiresAt: Date, scopes: Set<AuthScope>, tokenString: String)
```

> 

  - tokenString - Raw token value which is passed to the services.

#### Parameters

  - appId: Speechly application identifier.
  - deviceId: Speechly device identifier.
  - expiresAt: Token expiration timestamp.
  - scopes: Authorised token scopes.

## Properties

### `appId`

Speechly application identifier.

``` swift
let appId: UUID
```

### `deviceId`

Speechly device identifier.

``` swift
let deviceId: UUID
```

### `expiresAt`

Token expiration timestamp.

``` swift
let expiresAt: Date
```

### `scopes`

Authorised token scopes.

``` swift
let scopes: Set<AuthScope>
```

### `tokenString`

Raw token value which is passed to the services.

``` swift
let tokenString: String
```

## Methods

### `validate(appId:deviceId:expiresIn:)`

Validates the token against provided identifiers and expiration time.

``` swift
public func validate(appId: UUID, deviceId: UUID, expiresIn: TimeInterval) -> Bool
```

#### Parameters

  - appId: Speechly application identifier to match against.
  - deviceId: Speechly device identifier to match against.
  - expiresIn: Time interval within which the token should still be valid.

#### Returns

`true` if the token is valid, `false` otherwise.

### `validateExpiry(expiresIn:)`

Validates token expiration time.

``` swift
public func validateExpiry(expiresIn: TimeInterval) -> Bool
```

#### Parameters

  - expiresIn: Time interval within which the token should still be valid.

#### Returns

`true` if the token will not expire in that time interval, `false` otherwise.
