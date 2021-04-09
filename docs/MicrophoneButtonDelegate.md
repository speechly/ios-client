# MicrophoneButtonDelegate

``` swift
public protocol MicrophoneButtonDelegate
```

## Requirements

### didOpenMicrophone(\_:​)

``` swift
func didOpenMicrophone(_ button: MicrophoneButtonView)
```

### didCloseMicrophone(\_:​)

``` swift
func didCloseMicrophone(_ button: MicrophoneButtonView)
```

### speechButtonImageForAuthorizationStatus(\_:​status:​)

``` swift
func speechButtonImageForAuthorizationStatus(_ button: MicrophoneButtonView, status: AVAuthorizationStatus) -> UIImage?
```
