# makeChannel(addr:group:)

A function that creates a new gRPC channel for the provided address.

``` swift
public func makeChannel(addr: String, group: EventLoopGroup) throws -> GRPCChannel
```

## Parameters

  - addr: The address of the gRPC server to connect to.
  - group: The NIO evenloop group to use for backing the channel.

## Returns

A gRPC channel connected to given server address and backed by given eventloop group.
