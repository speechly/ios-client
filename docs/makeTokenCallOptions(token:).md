# makeTokenCallOptions(token:)

A function that creates new gRPC call options (metadata) that contains an authorisation token.

``` swift
public func makeTokenCallOptions(token: String) -> CallOptions
```

The resulting metadata has a pair that looks like `Authorization: Bearer ${token}`.

## Parameters

  - token: The token to use.

## Returns

A `CallOptions` that contain custom metadata with the token as authorization bearer.
