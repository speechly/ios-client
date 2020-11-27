# GRPCAddress

A gRPC service address.

``` swift
public struct GRPCAddress
```

Encapsulates together the host, the port and secure / non-secure properties for connecting to gRPC service endpoints.

## Initializers

### `init(host:port:secure:)`

Creates a new gRPC address.

``` swift
public init(host: String, port: Int, secure: Bool)
```

#### Parameters

  - host: The host of the remote gRPC service.
  - port: The port of the remote gRPC service.
  - secure: Whether the connection to the service should use TLS.

### `init(addr:)`

Creates a new gRPC address.

``` swift
public init(addr: String) throws
```

> 

#### Parameters

  - addr: The address of the remote gRPC service.

## Properties

### `host`

The host of the remote gRPC service.

``` swift
let host: String
```

### `port`

The port of the remote gRPC service.

``` swift
let port: Int
```

### `secure`

Whether the connection should use TLS.

``` swift
let secure: Bool
```
