# SpeechButtonDelegate

``` swift
public protocol SpeechButtonDelegate: NSObjectProtocol
```

## Inheritance

`NSObjectProtocol`

## Requirements

### clientForSpeechButton(\_:​)

``` swift
func clientForSpeechButton(_ button: SpeechButton) -> SpeechClient?
```

### speechButtonImageForAuthorizationStatus(\_:​status:​)

``` swift
func speechButtonImageForAuthorizationStatus(_ button: SpeechButton, status: AVAuthorizationStatus) -> UIImage?
```
