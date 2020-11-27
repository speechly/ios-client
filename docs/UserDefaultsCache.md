# UserDefaultsCache

A cache implementation that uses `UserDefaults` as the backing storage.

``` swift
public class UserDefaultsCache
```

## Inheritance

[`CacheProtocol`](CacheProtocol)

## Initializers

### `init()`

Creates a new `UserDefaultsCache` instance.

``` swift
public convenience init()
```

### `init(storage:)`

Creates a new `UserDefaultsCache` instance.

``` swift
public init(storage: UserDefaults)
```

#### Parameters

  - storage: The `UserDefaults` storage to use as the backend.

## Methods

### `setValue(_:forKey:)`

``` swift
public func setValue(_ value: String, forKey: String)
```

### `getValue(forKey:)`

``` swift
public func getValue(forKey: String) -> String?
```
