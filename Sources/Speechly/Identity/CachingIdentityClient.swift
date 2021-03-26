import Foundation
import NIO

// MARK: - CachingIdentityClient definition.

/// A client for Speechly Identity gRPC API which provides token caching functionality.
///
/// The cache is implemented as read-through and transparent for the consumer.
public class CachingIdentityClient {
    /// The protocol constraints for backing base Identity client.
    public typealias PromisableClient = IdentityClientProtocol & Promisable

    private let baseClient: PromisableClient
    private let cache: CacheProtocol

    private let defaultExpiresIn: TimeInterval = 60 * 60
    private var memCache: [String: ApiAccessToken] = [:]

    /// Creates a new client.
    ///
    /// - Parameters:
    ///     - baseClient: A base Identity client to use for fetching tokens.
    ///     - cache: A cache to use for storing tokens.
    public init(baseClient: PromisableClient, cache: CacheProtocol) {
        self.baseClient = baseClient
        self.cache = cache
    }
}

// MARK: - IdentityClientProtocol conformance.

extension CachingIdentityClient: IdentityClientProtocol {
    public func authenticate(appId: UUID, deviceId: UUID) -> EventLoopFuture<ApiAccessToken> {
        let token = loadToken(key: appId, deviceId: deviceId)

        if token != nil && token!.validate(key: appId, deviceId: deviceId, expiresIn: defaultExpiresIn) {
            return self.baseClient.makeSucceededFuture(token!)
        }

        return self.baseClient
            .authenticate(appId: appId, deviceId: deviceId)
            .map({ newToken in self.storeToken(token: newToken) })
    }

    public func authenticateProject(projectId: UUID, deviceId: UUID) -> EventLoopFuture<ApiAccessToken> {
        let token = loadToken(key: projectId, deviceId: deviceId)

        if token != nil && token!.validate(key: projectId, deviceId: deviceId, expiresIn: defaultExpiresIn) {
            return self.baseClient.makeSucceededFuture(token!)
        }

        return self.baseClient
            .authenticateProject(projectId: projectId, deviceId: deviceId)
            .map({ newToken in self.storeToken(token: newToken) })
    }

    private func loadToken(key: UUID, deviceId: UUID) -> ApiAccessToken? {
        let cacheKey = makeCacheKey(key: key, deviceId: deviceId)

        if let val = self.memCache[cacheKey] {
            return val
        }

        guard let cachedValue = cache.getValue(forKey: cacheKey) else {
            return nil
        }

        return ApiAccessToken(tokenString: cachedValue)
    }

    private func storeToken(token: ApiAccessToken) -> ApiAccessToken {
        let cacheKey = makeCacheKey(key: token.key(), deviceId: token.deviceId)

        self.memCache[cacheKey] = token
        self.cache.setValue(token.tokenString, forKey: cacheKey)

        return token
    }

    private func makeCacheKey(key: UUID, deviceId: UUID) -> String {
        return "authToken.\(key.hashValue).\(deviceId.hashValue)"
    }
}
