# GRPCAddress.ParseError

Errors thrown when parsing the address.

``` swift
public enum ParseError
```

## Inheritance

`Error`

## Enumeration Cases

### `unsupportedScheme`

Thrown when the address contains an invalid scheme.

``` swift
case unsupportedScheme
```

### `unsupportedURL`

Thrown when the address contains a URL that cannot be parsed with `URL.init(string:​ addr)`.

``` swift
case unsupportedURL
```

### `missingHost`

Thrown when the address does not contain a valid host.

``` swift
case missingHost
```
