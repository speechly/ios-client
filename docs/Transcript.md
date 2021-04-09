# Transcript

A speech transcript.

``` swift
public struct Transcript: Hashable
```

A transcript is a single word in a phrase recognised from the audio.
e.g. a phrase "two glasses" will have two transcripts, "two" and "glasses".

## Inheritance

`Comparable`, `Hashable`, `Identifiable`

## Initializers

### `init(index:value:startOffset:endOffset:isFinal:)`

Creates a new transcript.

``` swift
public init(index: Int, value: String, startOffset: TimeInterval, endOffset: TimeInterval, isFinal: Bool)
```

#### Parameters

  - index: the index of the transcript.
  - value: the value of the transcript.
  - startOffset: the time offset of the beginning of the transcript in the phrase.
  - endOffset: the time offset of the end of the transcript in the phrase.
  - isFinal: the status of the transcript.

## Properties

### `index`

The index of the transcript in the phrase.

``` swift
let index: Int
```

### `value`

The value of the transcript, e.g. "glasses".
The case is not guaranteed, it is up to the consumer to decide whether to change it or not.

``` swift
let value: String
```

### `startOffset`

The time offset of the beginning of the transcript in the audio, relative to the beginning of the phrase.

``` swift
let startOffset: TimeInterval
```

### `endOffset`

The time offset of the end of the transcript in the audio, relative to the beginning of the phrase.

``` swift
let endOffset: TimeInterval
```

### `isFinal`

The status of the transcript.
`true` for finalised intents, `false` otherwise.

``` swift
let isFinal: Bool
```

> 

### `id`

``` swift
var id: Int
```

## Methods

### `<(lhs:rhs:)`

``` swift
public static func <(lhs: Transcript, rhs: Transcript) -> Bool
```

### `<=(lhs:rhs:)`

``` swift
public static func <=(lhs: Transcript, rhs: Transcript) -> Bool
```

### `>=(lhs:rhs:)`

``` swift
public static func >=(lhs: Transcript, rhs: Transcript) -> Bool
```

### `>(lhs:rhs:)`

``` swift
public static func >(lhs: Transcript, rhs: Transcript) -> Bool
```
