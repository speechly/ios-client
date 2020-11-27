# SpeechSegment

A segment is a part of a recognition context (or a phrase) which is defined by an intent.

``` swift
public struct SpeechSegment: Hashable, Identifiable
```

e.g. a phrase "book a restaurant and send an invitation to John" contains two intents,
"book" and "send an invitation". Thus, the phrase will also contain two segments, "book a restaurant" and
"send an invitation to John". A segment has to have exactly one intent that defines it, but it's allowed to have
any number of entities and transcripts.

A segment can be final or tentative. Final segments are guaranteed to only contain final intent, entities
and transcripts. Tentative segments can have a mix of final and tentative parts.

## Inheritance

`Comparable`, `Hashable`, `Identifiable`

## Initializers

### `init(segmentId:contextId:)`

Creates a new tentative segment with empty intent, entities and transcripts.

``` swift
public init(segmentId: Int, contextId: String)
```

#### Parameters

  - segmentId: The identifier of the segment within a `SpeechContext`.
  - contextId: The identifier of the `SpeechContext` that this segment belongs to.

### `init(segmentId:contextId:isFinal:intent:entities:transcripts:)`

Creates a new segment with provided parameters.

``` swift
public init(segmentId: Int, contextId: String, isFinal: Bool, intent: SpeechIntent, entities: [SpeechEntity], transcripts: [SpeechTranscript])
```

> 

#### Parameters

  - segmentId: The identifier of the segment within a `SpeechContext`.
  - contextId: The identifier of the `SpeechContext` that this segment belongs to.
  - isFinal: Indicates whether the segment is final or tentative.
  - intent: The intent of the segment.
  - entities: The entities belonging to the segment.
  - transcripts: The transcripts belonging to the segment.

## Properties

### `id`

A unique identifier of the segment.

``` swift
let id: String
```

### `segmentId`

The identifier of the segment, which is unique when combined with `contextId`.

``` swift
let segmentId: Int
```

### `contextId`

A unique identifier of the `SpeechContext` that the segment belongs to

``` swift
let contextId: String
```

### `isFinal`

The status of the segment. `true` when the segment is finalised, `false` otherwise.

``` swift
var isFinal: Bool = false
```

### `intent`

The intent of the segment. Returns an empty tentative intent by default.

``` swift
var intent: SpeechIntent = SpeechIntent.Empty
```

### `entities`

The entities belonging to the segment.

``` swift
var entities: [SpeechEntity]
```

### `transcripts`

The transcripts belonging to the segment.

``` swift
var transcripts: [SpeechTranscript]
```

## Methods

### `<(lhs:rhs:)`

``` swift
public static func <(lhs: SpeechSegment, rhs: SpeechSegment) -> Bool
```

### `<=(lhs:rhs:)`

``` swift
public static func <=(lhs: SpeechSegment, rhs: SpeechSegment) -> Bool
```

### `>=(lhs:rhs:)`

``` swift
public static func >=(lhs: SpeechSegment, rhs: SpeechSegment) -> Bool
```

### `>(lhs:rhs:)`

``` swift
public static func >(lhs: SpeechSegment, rhs: SpeechSegment) -> Bool
```
