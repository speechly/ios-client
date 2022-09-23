# Intent

A speech intent.

``` swift
public struct Intent: Hashable
```

An intent is part of a phrase which defines the action of the phrase,
e.g. a phrase "book a restaurant and send an invitation to John" contains two intents,
"book" and "send an invitation".

Intents can and should be used to dispatch the action that the user wants to do in the app
(e.g. book a meeting, schedule a flight, reset the form).

## Inheritance

`Comparable`, `Hashable`, `Identifiable`

## Initializers

### `init(value:isFinal:)`

Creates a new intent.

``` swift
public init(value: String, isFinal: Bool)
```

#### Parameters

  - value: the value of the intent.
  - isFinal: the status of the intent.

## Properties

### `Empty`

An empty intent. Can be used as default value in other places.

``` swift
let Empty
```

### `value`

The value of the intent, as defined in Speechly application configuration.
e.g. in the example `*book book a [burger restaurant](restaurant_type)` it would be `book```` swift
let value: String
```

### `isFinal`

The status of the intent.
`true` for finalised intents, `false` otherwise.

``` swift
let isFinal: Bool
```

> 

### `id`

``` swift
var id: String
```

## Methods

### `<(lhs:rhs:)`

``` swift
public static func <(lhs: Intent, rhs: Intent) -> Bool
```

### `<=(lhs:rhs:)`

``` swift
public static func <=(lhs: Intent, rhs: Intent) -> Bool
```

### `>=(lhs:rhs:)`

``` swift
public static func >=(lhs: Intent, rhs: Intent) -> Bool
```

### `>(lhs:rhs:)`

``` swift
public static func >(lhs: Intent, rhs: Intent) -> Bool
```
