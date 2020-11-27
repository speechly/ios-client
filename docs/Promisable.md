# Promisable

A protocol that defines methods for making succeeded and failed futures.

``` swift
public protocol Promisable
```

## Requirements

### makeSucceededFuture(\_:​)

Creates a new succeeded future with value `value`.

``` swift
func makeSucceededFuture<T>(_ value: T) -> EventLoopFuture<T>
```

#### Parameters

  - value: The value to wrap in the future

#### Returns

An `EventLoopFuture` that always succeeds with `value`.

### makeFailedFuture(\_:​)

Creates a new failed future with error `error`.

``` swift
func makeFailedFuture<T>(_ error: Error) -> EventLoopFuture<T>
```

#### Parameters

  - error: The error to wrap in the future

#### Returns

An `EventLoopFuture` that always fails with `error`.
