# SpeechEntity

A speech entity.

``` swift
public struct SpeechEntity: Hashable, Identifiable
```

An entity is a specific object in the phrase that falls into some kind of category,
e.g. in a SAL example "\*book book a [burger restaurant](restaurant_type) for [tomorrow](date)"
"burger restaurant" would be an entity of type `restaurant_type`,
and "tomorrow" would be an entity of type `date`.

An entity has a start and end indices which map to the indices of `SpeechTranscript`s,
e.g. in the example "\*book book a [burger restaurant](restaurant_type) for [tomorrow](date)" it would be:

  - Entity "burger restaurant" - `startIndex = 2, endIndex = 3`

  - Entity "tomorrow" - `startIndex = 5, endIndex = 5`

The start index is inclusive, but the end index is exclusive, i.e. the interval is `[startIndex, endIndex)`.

## Inheritance

`Comparable`, `Hashable`, `Identifiable`

## Initializers

### `init(value:type:startIndex:endIndex:isFinal:)`

Creates a new entity.

``` swift
public init(value: String, type: String, startIndex: Int, endIndex: Int, isFinal: Bool)
```

#### Parameters

  - value: the value of the entity.
  - type: the type of the entity.
  - startIndex: the index of the beginning of the entity in a segment.
  - endIndex: the index of the end of the entity in a segment.
  - isFinal: the status of the entity.

## Properties

### `id`

The identifier of the entity, unique within a `SpeechSegment`.
Consists of the combination of start and end indices.

``` swift
let id: ID
```

### `value`

The value of the entity, as detected by the API and defined by SAL.

``` swift
let value: String
```

Given SAL `*book book a [burger restaurant](restaurant_type)` and an audio `book an italian place`,
The value will be `italian place`.

### `type`

The type (or class) of the entity, as detected by the API and defined by SAL.

``` swift
let type: String
```

Given SAL `*book book a [burger restaurant](restaurant_type)` and an audio `book an italian place`,
The type will be `restaurant_type`.

### `startIndex`

Start index of the entity, correlates with an index of some `SpeechTranscript` in a `SpeechSegment`.

``` swift
let startIndex: Int
```

### `endIndex`

End index of the entity, correlates with an index of some `SpeechTranscript` in a `SpeechSegment`.

``` swift
let endIndex: Int
```

### `isFinal`

The status of the entity.
`true` for finalised entities, `false` otherwise.

``` swift
let isFinal: Bool
```

> 

## Methods

### `<(lhs:rhs:)`

``` swift
public static func <(lhs: SpeechEntity, rhs: SpeechEntity) -> Bool
```

### `<=(lhs:rhs:)`

``` swift
public static func <=(lhs: SpeechEntity, rhs: SpeechEntity) -> Bool
```

### `>=(lhs:rhs:)`

``` swift
public static func >=(lhs: SpeechEntity, rhs: SpeechEntity) -> Bool
```

### `>(lhs:rhs:)`

``` swift
public static func >(lhs: SpeechEntity, rhs: SpeechEntity) -> Bool
```
