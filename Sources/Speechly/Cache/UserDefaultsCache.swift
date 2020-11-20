import Foundation

// MARK: - UserDefaultsStorage definition.

/// A cache implementation that uses `UserDefaults` as the backing storage.
public class UserDefaultsCache {
    private let storage: UserDefaults

    /// Creates a new `UserDefaultsCache` instance.
    public convenience init() {
        self.init(storage: UserDefaults.standard)
    }

    /// Creates a new `UserDefaultsCache` instance.
    ///
    /// - Parameters:
    ///     - storage: The `UserDefaults` storage to use as the backend.
    public init(storage: UserDefaults) {
        self.storage = storage
    }
}

// MARK: - CacheStorageProtocol conformance.

extension UserDefaultsCache: CacheProtocol {
    public func setValue(_ value: String, forKey: String) {
        self.storage.set(value, forKey: forKey)
    }

    public func getValue(forKey: String) -> String? {
        return self.storage.string(forKey: forKey)
    }
}
