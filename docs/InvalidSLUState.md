# InvalidSLUState

Possible invalid states of the client, eg. if `startContext` is called without connecting to API first.

``` swift
public enum InvalidSLUState
```

## Inheritance

`Error`

## Enumeration Cases

### `notConnected`

``` swift
case notConnected
```

### `contextAlreadyStarted`

``` swift
case contextAlreadyStarted
```

### `contextNotStarted`

``` swift
case contextNotStarted
```
