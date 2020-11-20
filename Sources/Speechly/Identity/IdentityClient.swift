import Foundation
import NIO
import GRPC
import SpeechlyAPI

// MARK: - IdentityClient definition.

/// A client for Speechly Identity gRPC API.
///
/// Exposes functionality for authenticating identifiers in exchange for API access tokens.
public class IdentityClient {
    private let group: EventLoopGroup
    private let client: IdentityApiClient

    /// Creates a new client.
    ///
    /// - Parameters:
    ///     - addr: The address of Speechly Identity API service.
    ///     - loopGroup: `NIO.EventLoopGroup` to use for the client.
    public convenience init(addr: String, loopGroup: EventLoopGroup) throws {
        let channel = try makeChannel(addr: addr, group: loopGroup)
        let client = Speechly_Identity_V1_IdentityClient(channel: channel)

        self.init(group: loopGroup, client: client)
    }

    /// Alias for Speechly Identity client protocol.
    public typealias IdentityApiClient = Speechly_Identity_V1_IdentityClientProtocol

    /// Creates a new client.
    ///
    /// - Parameters:
    ///     - loopGroup: `NIO.EventLoopGroup` to use for the client.
    ///     - client: `IdentityApiClient` implementation.
    public init(group: EventLoopGroup, client: IdentityApiClient) {
        self.group = group
        self.client = client
    }

    deinit {
        do {
            try self.client.channel.close().wait()
        } catch {
            print("Error closing gRPC channel:", error)
        }
    }
}

// MARK: - Promisable protocol conformance.

extension IdentityClient: Promisable {
    public func makeFailedFuture<T>(_ error: Error) -> EventLoopFuture<T> {
        return self
            .group.next()
            .makeFailedFuture(error)
    }

    public func makeSucceededFuture<AuthToken>(_ value: AuthToken) -> EventLoopFuture<AuthToken> {
        return self
            .group.next()
            .makeSucceededFuture(value)
    }
}

// MARK: - IdentityClientProtocol conformance.

extension IdentityClient: IdentityClientProtocol {
    typealias IdentityLoginRequest = Speechly_Identity_V1_LoginRequest

    /// Errors returned by the client.
    public enum IdentityClientError: Error {
        /// The error returned if the API returns an invalid access token.
        case invalidTokenPayload
    }

    public func authenticate(appId: UUID, deviceId: UUID) -> EventLoopFuture<ApiAccessToken> {
        let request = IdentityLoginRequest.with {
            $0.appID = appId.uuidString.lowercased()
            $0.deviceID = deviceId.uuidString.lowercased()
        }

        return self.client.login(request).response.flatMapThrowing { response throws in
            guard let token = ApiAccessToken(tokenString: response.token) else {
                throw IdentityClientError.invalidTokenPayload
            }

            return token
        }
    }
}
