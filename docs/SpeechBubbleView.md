# SpeechBubbleView

``` swift
public class SpeechBubbleView: UIView
```

## Inheritance

`UIView`

## Initializers

### `init()`

``` swift
public init()
```

## Properties

### `isShowing`

``` swift
var isShowing: Bool
```

### `autohideInterval`

``` swift
var autohideInterval: TimeInterval? = 3
```

### `text`

``` swift
var text: String?
```

### `font`

``` swift
var font: UIFont!
```

### `textColor`

``` swift
var textColor: UIColor!
```

### `color`

``` swift
var color: UIColor!
```

## Methods

### `show(animated:)`

``` swift
public func show(animated: Bool = true)
```

### `hide(animated:)`

``` swift
public func hide(animated: Bool = true)
```

### `pulse(duration:scale:)`

``` swift
public func pulse(duration: TimeInterval = 0.5, scale: CGFloat = 1.2)
```
