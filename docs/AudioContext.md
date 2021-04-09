# AudioContext

The speech recognition context.

``` swift
public struct AudioContext: Hashable, Identifiable
```

A single context aggregates messages from SLU API, which correspond to the audio portion
sent to the API within a single recognition stream.

## Inheritance

`Comparable`, `Hashable`, `Identifiable`

## Initializers

### `init(id:)`

Creates a new empty speech context.

``` swift
public init(id: String)
```

#### Parameters

  - id: The identifier of the context.

### `init(id:segments:)`

Creates a new speech context.

``` swift
public init(id: String, segments: [Segment])
```

> 

#### Parameters

  - id: The identifier of the context.
  - segments: The segments which belong to the context.

## Properties

### `id`

The ID of the segment, assigned by the API.

``` swift
let id: String
```

### `segments`

The segments belonging to the segment, can be empty if there was nothing recognised from the audio.

``` swift
var segments: [Segment]
```

## Methods

### `<(lhs:rhs:)`

``` swift
public static func <(lhs: AudioContext, rhs: AudioContext) -> Bool
```

### `<=(lhs:rhs:)`

``` swift
public static func <=(lhs: AudioContext, rhs: AudioContext) -> Bool
```

### `>=(lhs:rhs:)`

``` swift
public static func >=(lhs: AudioContext, rhs: AudioContext) -> Bool
```

### `>(lhs:rhs:)`

``` swift
public static func >(lhs: AudioContext, rhs: AudioContext) -> Bool
```
