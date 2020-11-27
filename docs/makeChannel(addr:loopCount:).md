# makeChannel(addr:loopCount:)

A function that creates a new gRPC channel for the provided address.
It will also create a NIO eventloop group with the specified loop count.

``` swift
public func makeChannel(addr: String, loopCount: Int) throws -> GRPCChannel
```

## Parameters

  - addr: The address of the gRPC server to connect to.
  - loopCount: The number of event loops to create in the event loop group.

## Returns

A gRPC channel connected to given server address and backed by a platform-specific eventloop group.
