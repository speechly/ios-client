# SluConfig

SLU stream configuration describes the audio data sent to the stream.
If misconfigured, the recognition stream will not produce any useful results.

``` swift
public struct SluConfig
```

## Properties

### `sampleRate`

The sample rate of the audio sent to the stream, in Hertz.

``` swift
let sampleRate: Double
```

### `channels`

The number of channels in the audio sent to the stream.

``` swift
let channels: UInt32
```

### `languageCode`

The language of the audio sent to the stream.
Must be the same as the language used for configuring Speechly application,
which is passed in the token to `start`.

``` swift
let languageCode: LanguageCode
```
