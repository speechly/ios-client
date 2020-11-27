# SpeechClientDelegate

Delegate called when a speech client handles messages from the API or catches an error.

``` swift
public protocol SpeechClientDelegate: class
```

The intended use of this protocol is with `SpeechClientProtocol`.

> 

## Inheritance

`class`

## Requirements

### speechlyClientDidCatchError(\_:​error:​)

Called when the client catches an error.

``` swift
func speechlyClientDidCatchError(_ speechlyClient: SpeechClientProtocol, error: SpeechClientError)
```

#### Parameters

  - error: The error which was caught.

### speechlyClientDidStart(\_:​)

Called after the client has acknowledged a recognition context start.

``` swift
func speechlyClientDidStart(_ speechlyClient: SpeechClientProtocol)
```

### speechlyClientDidStop(\_:​)

Called after the client has acknowledged a recognition context stop.

``` swift
func speechlyClientDidStop(_ speechlyClient: SpeechClientProtocol)
```

### speechlyClientDidUpdateSegment(\_:​segment:​)

Called after the client has processed an update to current `SpeechSegment`.

``` swift
func speechlyClientDidUpdateSegment(_ speechlyClient: SpeechClientProtocol, segment: SpeechSegment)
```

When the client receives messages from the API, it will use them to update the state of current speech segment,
and dispatch the updated state to the delegate. The delegate can use these updates to react to the user input
by using the intent, entities and transcripts contained in the segment.

Only one segment is active at a time, but since the processing is asynchronous,
it is possible to have out-of-order delivery of segments.

#### Parameters

  - segment: The speech segment that has been updated.

### speechlyClientDidReceiveTranscript(\_:​contextId:​segmentId:​transcript:​)

Called after the client has received a new transcript message from the API.

``` swift
func speechlyClientDidReceiveTranscript(_ speechlyClient: SpeechClientProtocol, contextId: String, segmentId: Int, transcript: SpeechTranscript)
```

#### Parameters

  - contextId: The ID of the recognition context that the transcript belongs to.
  - segmentId: The ID of the speech segment that the transcript belongs to.
  - transcript: The transcript received from the API.

### speechlyClientDidReceiveEntity(\_:​contextId:​segmentId:​entity:​)

Called after the client has received a new entity message from the API.

``` swift
func speechlyClientDidReceiveEntity(_ speechlyClient: SpeechClientProtocol, contextId: String, segmentId: Int, entity: SpeechEntity)
```

#### Parameters

  - contextId: The ID of the recognition context that the entity belongs to.
  - segmentId: The ID of the speech segment that the entity belongs to.
  - entity: The entity received from the API.

### speechlyClientDidReceiveIntent(\_:​contextId:​segmentId:​intent:​)

Called after the client has received a new intent message from the API.

``` swift
func speechlyClientDidReceiveIntent(_ speechlyClient: SpeechClientProtocol, contextId: String, segmentId: Int, intent: SpeechIntent)
```

#### Parameters

  - contextId: The ID of the recognition context that the intent belongs to.
  - segmentId: The ID of the speech segment that the intent belongs to.
  - transcript: The intent received from the API.
