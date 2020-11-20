import Foundation

// MARK: - ApiAccessToken definition.

/// A struct representing an access token returned by Speechly Identity service.
///
/// The token is required for other application-specific Speechly APIs like Speechly SLU API.
public struct ApiAccessToken: Hashable {
    /// Token authorisation scopes.
    /// They determine which services can be accessed with this token.
    public enum AuthScope {
        /// Speechly SLU service.
        case SLU

        /// Speechly WLU service.
        case WLU
    }

    /// Speechly application identifier.
    public let appId: UUID

    /// Speechly device identifier.
    public let deviceId: UUID

    /// Token expiration timestamp.
    public let expiresAt: Date

    /// Authorised token scopes.
    public let scopes: Set<AuthScope>

    /// Raw token value which is passed to the services.
    public let tokenString: String

    /// Creates a new token from a raw token representation, returned by Identity API.
    ///
    /// - Important: This initialiser will return `nil` if the string value could not be decoded.
    ///
    /// - Parameter tokenString:raw token value obtained from Identity API or cache.
    public init?(tokenString: String) {
        guard let decoded = parseToken(tokenString) else {
            return nil
        }

        guard let appId = UUID(uuidString: decoded.appId) else {
            return nil
        }

        guard let deviceId = UUID(uuidString: decoded.deviceId) else {
            return nil
        }

        self.init(
            appId: appId,
            deviceId: deviceId,
            expiresAt: Date(timeIntervalSince1970: TimeInterval(decoded.exp)),
            scopes: parseScope(decoded.scope),
            tokenString: tokenString
        )
    }

    /// Creates a new token.
    ///
    /// - Important: This initialiser WILL NOT attempt to decode and validate the `tokenString`.
    ///
    /// - Parameters:
    ///     - appId: Speechly application identifier.
    ///     - deviceId: Speechly device identifier.
    ///     - expiresAt: Token expiration timestamp.
    ///     - scopes: Authorised token scopes.
    ///     - tokenString - Raw token value which is passed to the services.
    public init(appId: UUID, deviceId: UUID, expiresAt: Date, scopes: Set<AuthScope>, tokenString: String) {
        self.appId = appId
        self.deviceId = deviceId
        self.expiresAt = expiresAt
        self.scopes = scopes
        self.tokenString = tokenString
    }

    /// Validates the token against provided identifiers and expiration time.
    ///
    /// - Parameters:
    ///     - appId: Speechly application identifier to match against.
    ///     - deviceId: Speechly device identifier to match against.
    ///     - expiresIn: Time interval within which the token should still be valid.
    /// - Returns: `true` if the token is valid, `false` otherwise.
    public func validate(appId: UUID, deviceId: UUID, expiresIn: TimeInterval) -> Bool {
        return self.appId == appId && self.deviceId == deviceId && self.validateExpiry(expiresIn: expiresIn)
    }

    /// Validates token expiration time.
    ///
    /// - Parameters:
    ///     - expiresIn: Time interval within which the token should still be valid.
    /// - Returns: `true` if the token will not expire in that time interval, `false` otherwise.
    public func validateExpiry(expiresIn: TimeInterval) -> Bool {
        return !self.expiresAt.timeIntervalSinceNow.isLessThanOrEqualTo(expiresIn)
    }
}

// MARK: - Internal token parsing logic

private struct DecodedToken: Decodable {
    let appId: String
    let deviceId: String
    let scope: String
    let exp: Int
}

private func parseToken(_ token: String) -> DecodedToken? {
    guard case let parts = token.split(separator: "."), parts.count == 3 else {
        return nil
    }

    guard let decoded = base64Decode(String(parts[1])) else {
        return nil
    }

    return try? JSONDecoder().decode(DecodedToken.self, from: decoded)
}

private func parseScope(_ scope: String) -> Set<ApiAccessToken.AuthScope> {
    var scopes: Set<ApiAccessToken.AuthScope> = []

    for s in scope.split(separator: " ") {
        switch(s) {
        case "slu":
            scopes.update(with: ApiAccessToken.AuthScope.SLU)
        case "wlu":
            scopes.update(with: ApiAccessToken.AuthScope.WLU)
        default:
            continue
        }
    }

    return scopes
}

private func base64Decode(_ value: String) -> Data? {
    var st = value
    if (value.count % 4 != 0){
        st += String(repeating: "=", count: (value.count % 4))
    }

    return Data(base64Encoded: st)
}
