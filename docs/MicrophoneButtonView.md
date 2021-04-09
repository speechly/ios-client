# MicrophoneButtonView

``` swift
public class MicrophoneButtonView: UIView
```

## Inheritance

`UIView`

## Initializers

### `init(diameter:delegate:)`

``` swift
public init(diameter: CGFloat = 80, delegate: MicrophoneButtonDelegate)
```

## Properties

### `borderImage`

``` swift
var borderImage: UIImage?
```

### `blurEffectImage`

``` swift
var blurEffectImage: UIImage?
```

### `holdToTalkText`

``` swift
var holdToTalkText: String!
```

### `pressedScale`

``` swift
var pressedScale: CGFloat = 1.5
```

### `isPressed`

``` swift
var isPressed: Bool = false
```

## Methods

### `reloadAuthorizationStatus()`

``` swift
public func reloadAuthorizationStatus()
```
