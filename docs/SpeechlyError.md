# SpeechlyError

Errors caught by `SpeechClientProtocol` and dispatched to `SpeechClientDelegate`.

``` swift
public enum SpeechlyError
```

## Inheritance

`Error`

## Enumeration Cases

### `networkError`

A network-level error.
Usually these errors are unrecoverable and require a full restart of the client.

``` swift
case networkError(: String)
```

### `audioError`

An error within the audio recorder stack.
Normally these errors are recoverable and do not require any special handling.
However, these errors will result in downgraded recognition performance.

``` swift
case audioError(: String)
```

### `apiError`

An error within the API.
Normally these errors are recoverable, but they may result in dropped API responses.

``` swift
case apiError(: String)
```

### `parseError`

An error within the API message parsing logic.
These errors are fully recoverable, but will result in missed speech segment updates.

``` swift
case parseError(: String)
```
