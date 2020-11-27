# CacheProtocol

A protocol for a cache storage.

``` swift
public protocol CacheProtocol
```

The purpose of a cache storage is to persistently store string keys and values.
The cache is used for storing things like device identifiers, authentication tokens and such.

## Requirements

### setValue(\_:​forKey:​)

Adds a value with a specified key to the cache.

``` swift
func setValue(_ value: String, forKey: String)
```

#### Parameters

  - value: The value to store in the cache.
  - forKey: The key to use for addressing the value.

### getValue(forKey:​)

Retrieves the value from the cache using the provided key.

``` swift
func getValue(forKey: String) -> String?
```

#### Parameters

  - forKey: The key to use for addressing the value.

#### Returns

The value stored in the cache or `nil` if no value could be found for the key provided.
