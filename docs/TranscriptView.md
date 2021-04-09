# TranscriptView

``` swift
public class TranscriptView: UIView
```

## Inheritance

`UIView`

## Initializers

### `init()`

``` swift
public init()
```

## Properties

### `segment`

``` swift
var segment: Speechly.Segment?
```

### `font`

``` swift
var font: UIFont = UIFont(name: "AvenirNextCondensed-Bold", size: 20)!
```

### `textColor`

``` swift
var textColor: UIColor = UIColor.white
```

### `highlightedTextColor`

``` swift
var highlightedTextColor: UIColor
```

### `autohideInterval`

``` swift
var autohideInterval: TimeInterval? = 3
```

## Methods

### `configure(segment:animated:)`

``` swift
public func configure(segment: Speechly.Segment?, animated: Bool)
```

### `hide(animated:)`

``` swift
public func hide(animated: Bool)
```
