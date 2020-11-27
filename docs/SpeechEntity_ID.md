# SpeechEntity.ID

A custom ID implementation for `SpeechEntity`.
Since entities have two indices, start and end,
this struct encapsulates the two for indexing and sorting purposes.

``` swift
public struct ID: Hashable, Comparable
```

## Inheritance

`Comparable`, `Hashable`

## Properties

### `start`

The start index.

``` swift
let start: Int
```

### `end`

The end index.

``` swift
let end: Int
```

## Methods

### `<(lhs:rhs:)`

``` swift
public static func <(lhs: ID, rhs: ID) -> Bool
```

### `<=(lhs:rhs:)`

``` swift
public static func <=(lhs: ID, rhs: ID) -> Bool
```

### `>=(lhs:rhs:)`

``` swift
public static func >=(lhs: ID, rhs: ID) -> Bool
```

### `>(lhs:rhs:)`

``` swift
public static func >(lhs: ID, rhs: ID) -> Bool
```
