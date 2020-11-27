# SluClientDelegate

Delegate called when an SLU client receives messages from the API or catches an error.
The intended use of this protocol is with `SluClientProtocol`.

``` swift
public protocol SluClientDelegate: class
```

> 

## Inheritance

`class`

## Requirements

### sluClientDidCatchError(\_:​error:​)

Called when the client catches an error.

``` swift
func sluClientDidCatchError(_ sluClient: SluClientProtocol, error: Error)
```

#### Parameters

  - error: The error which was caught.

### sluClientDidStopStream(\_:​status:​)

Called when a recognition stream is stopped from the server side.

``` swift
func sluClientDidStopStream(_ sluClient: SluClientProtocol, status: GRPCStatus)
```

#### Parameters

  - status: The status that the stream was closed with.

### sluClientDidReceiveContextStart(\_:​contextId:​)

Called when a recognition stream receives an audio context start message.

``` swift
func sluClientDidReceiveContextStart(_ sluClient: SluClientProtocol, contextId: String)
```

#### Parameters

  - contextId: The ID of the context that was started by the server.

### sluClientDidReceiveContextStop(\_:​contextId:​)

Called when a recognition stream receives an audio context stop message.

``` swift
func sluClientDidReceiveContextStop(_ sluClient: SluClientProtocol, contextId: String)
```

#### Parameters

  - contextId: The ID of the context that was stopped by the server.

### sluClientDidReceiveSegmentEnd(\_:​contextId:​segmentId:​)

Called when a recognition stream receives an segment end message.

``` swift
func sluClientDidReceiveSegmentEnd(_ sluClient: SluClientProtocol, contextId: String, segmentId: Int)
```

#### Parameters

  - contextId: The ID of the context that the segment belongs to.
  - segmentId: The ID of the segment which has ended.

### sluClientDidReceiveTentativeTranscript(\_:​contextId:​segmentId:​transcript:​)

Called when a recognition stream receives a tentative transcript message.

``` swift
func sluClientDidReceiveTentativeTranscript(_ sluClient: SluClientProtocol, contextId: String, segmentId: Int, transcript: TentativeTranscript)
```

#### Parameters

  - contextId: The ID of the context that the segment belongs to.
  - segmentId: The ID of the segment which the transcript belongs to.
  - transcript: The tentative transcript message.

### sluClientDidReceiveTentativeEntities(\_:​contextId:​segmentId:​entities:​)

Called when a recognition stream receives a tentative entities message.

``` swift
func sluClientDidReceiveTentativeEntities(_ sluClient: SluClientProtocol, contextId: String, segmentId: Int, entities: TentativeEntities)
```

#### Parameters

  - contextId: The ID of the context that the segment belongs to.
  - segmentId: The ID of the segment which the entities belongs to.
  - entities: The tentative entities message.

### sluClientDidReceiveTentativeIntent(\_:​contextId:​segmentId:​intent:​)

Called when a recognition stream receives a tentative intent message.

``` swift
func sluClientDidReceiveTentativeIntent(_ sluClient: SluClientProtocol, contextId: String, segmentId: Int, intent: TentativeIntent)
```

#### Parameters

  - contextId: The ID of the context that the segment belongs to.
  - segmentId: The ID of the segment which the intent belongs to.
  - intent: The tentative intent message.

### sluClientDidReceiveTranscript(\_:​contextId:​segmentId:​transcript:​)

Called when a recognition stream receives a final transcript message.

``` swift
func sluClientDidReceiveTranscript(_ sluClient: SluClientProtocol, contextId: String, segmentId: Int, transcript: Transcript)
```

#### Parameters

  - contextId: The ID of the context that the segment belongs to.
  - segmentId: The ID of the segment which the transcript belongs to.
  - transcript: The transcript message.

### sluClientDidReceiveEntity(\_:​contextId:​segmentId:​entity:​)

Called when a recognition stream receives a final entity message.

``` swift
func sluClientDidReceiveEntity(_ sluClient: SluClientProtocol, contextId: String, segmentId: Int, entity: Entity)
```

#### Parameters

  - contextId: The ID of the context that the segment belongs to.
  - segmentId: The ID of the segment which the entity belongs to.
  - entity: The entity message.

### sluClientDidReceiveIntent(\_:​contextId:​segmentId:​intent:​)

Called when a recognition stream receives a final intent message.

``` swift
func sluClientDidReceiveIntent(_ sluClient: SluClientProtocol, contextId: String, segmentId: Int, intent: Intent)
```

#### Parameters

  - contextId: The ID of the context that the segment belongs to.
  - segmentId: The ID of the segment which the intent belongs to.
  - intent: The intent message.
