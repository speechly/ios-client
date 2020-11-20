import Foundation

/// A gRPC service address.
///
/// Encapsulates together the host, the port and secure / non-secure properties for connecting to gRPC service endpoints.
public struct GRPCAddress {
    /// Errors thrown when parsing the address.
    public enum ParseError: Error {
        /// Thrown when the address contains an invalid scheme.
        case unsupportedScheme

        /// Thrown when the address contains a URL that cannot be parsed with `URL.init(string: addr)`.
        case unsupportedURL

        /// Thrown when the address does not contain a valid host.
        case missingHost
    }

    /// The host of the remote gRPC service.
    public let host: String

    /// The port of the remote gRPC service.
    public let port: Int

    /// Whether the connection should use TLS.
    public let secure: Bool

    /// Creates a new gRPC address.
    ///
    /// - Parameters:
    ///     - host: The host of the remote gRPC service.
    ///     - port: The port of the remote gRPC service.
    ///     - secure: Whether the connection to the service should use TLS.
    public init(host: String, port: Int, secure: Bool) {
        self.host = host
        self.port = port
        self.secure = secure
    }

    /// Creates a new gRPC address.
    ///
    /// - Parameters:
    ///     - addr: The address of the remote gRPC service.
    ///
    /// - Important: The address should be a valid URI with one of the supported custom schemes:
    ///     - `grpc://` represents the non-secure URI.
    ///     - `grpc+tls://` represents a URI that should use TLS for connection.
    public init(addr: String) throws {
        let schemeIdx: String.Index
        let secure: Bool

       let r1 = addr.range(of: "grpc://")
       let r2 = addr.range(of: "grpc+tls://")

        if r1 != nil {
          schemeIdx = r1!.upperBound
            secure = false
        } else if r2 != nil {
            schemeIdx = r2!.upperBound
            secure = true
        } else {
            throw ParseError.unsupportedScheme
        }

        let url = URL(string: addr.suffix(from: schemeIdx).base)
        if url == nil {
            throw ParseError.unsupportedURL
        }

        if url!.host == nil {
            throw ParseError.missingHost
        }

        var port = secure ? 443 : 80
        if url!.port != nil {
            port = url!.port!
        }

        self.init(host: url!.host!, port: port, secure: secure)
    }
}
