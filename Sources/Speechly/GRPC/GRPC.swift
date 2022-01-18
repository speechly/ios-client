import Foundation
import GRPC
import NIO

/// A function that creates a new gRPC channel for the provided address.
/// It will also create a NIO eventloop group with the specified loop count.
///
/// - Parameters:
///     - addr: The address of the gRPC server to connect to.
///     - loopCount: The number of event loops to create in the event loop group.
/// - Returns: A gRPC channel connected to given server address and backed by a platform-specific eventloop group.
public func makeChannel(addr: String, loopCount: Int) throws -> GRPCChannel {
    let group = PlatformSupport.makeEventLoopGroup(loopCount: loopCount)
    return try makeChannel(addr: addr, group: group)
}

/// A function that creates a new gRPC channel for the provided address.
///
/// - Parameters:
///     - addr: The address of the gRPC server to connect to.
///     - group: The NIO evenloop group to use for backing the channel.
/// - Returns: A gRPC channel connected to given server address and backed by given eventloop group.
public func makeChannel(addr: String, group: EventLoopGroup) throws -> GRPCChannel {
    let address = try GRPCAddress(addr: addr)
    let builder = { () -> ClientConnection.Builder in
        switch address.secure {
        case true:
            return ClientConnection.usingPlatformAppropriateTLS(for: group)
        case false:
            return ClientConnection.insecure(group: group)
        }
    }()

    return builder.connect(host: address.host, port: address.port)
}

/// A function that creates new gRPC call options (metadata) that contains an authorisation token.
///
/// The resulting metadata has a pair that looks like `Authorization: Bearer ${token}`.
///
/// - Parameters:
///     - token: The token to use.
/// - Returns: A `CallOptions` that contain custom metadata with the token as authorization bearer.
public func makeTokenCallOptions(token: String) -> CallOptions {
    return CallOptions(
        customMetadata: [
            "Authorization": "Bearer \(token)"
        ]
    )
}

