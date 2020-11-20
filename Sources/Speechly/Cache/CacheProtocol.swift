import Foundation

/// A protocol for a cache storage.
///
/// The purpose of a cache storage is to persistently store string keys and values.
/// The cache is used for storing things like device identifiers, authentication tokens and such.
public protocol CacheProtocol {
    /// Adds a value with a specified key to the cache.
    ///
    /// - Parameters:
    ///     - value: The value to store in the cache.
    ///     - forKey: The key to use for addressing the value.
    func setValue(_ value: String, forKey: String)

    /// Retrieves the value from the cache using the provided key.
    ///
    /// - Parameters:
    ///     - forKey: The key to use for addressing the value.
    /// - Returns: The value stored in the cache or `nil` if no value could be found for the key provided.
    func getValue(forKey: String) -> String?
}
