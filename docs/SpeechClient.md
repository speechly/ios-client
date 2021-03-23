# SpeechClient

A client that implements `SpeechClientProtocol` on top of Speechly SLU API and an audio recorder.

``` swift
public class SpeechClient
```

The client handles both the audio and the API streams, as well as API authentication,
caching access tokens and dispatching data to delegate.

The client is ready to use once initialised.

## Inheritance

[`AudioRecorderDelegate`](AudioRecorderDelegate), [`SluClientDelegate`](SluClientDelegate), [`SpeechClientProtocol`](SpeechClientProtocol)

## Initializers

### `init(appId:projectId:prepareOnInit:identityAddr:sluAddr:eventLoopGroup:delegateDispatchQueue:)`

Creates a new `SpeechClient`.

``` swift
public convenience init(appId: UUID? = nil, projectId: UUID? = nil, prepareOnInit: Bool = true, identityAddr: String = "grpc+tls://api.speechly.com", sluAddr: String = "grpc+tls://api.speechly.com", eventLoopGroup: EventLoopGroup = PlatformSupport.makeEventLoopGroup(loopCount: 1), delegateDispatchQueue: DispatchQueue = DispatchQueue(label: "com.speechly.iosclient.SpeechClient.delegateQueue")) throws
```

#### Parameters

  - appId: Speechly application identifier. Eiither appId or projectId is needed.
  - projectId: Speechly projectt identifier. Eiither appId or projectId is needed.
  - prepareOnInit: Whether the client should prepare on initialisation. Preparing means initialising the audio stack and fetching the authentication token for the API.
  - identityAddr: The address of Speechly Identity gRPC service. Defaults to Speechly public API endpoint.
  - sluAddr: The address of Speechly SLU gRPC service. Defaults to Speechly public API endpoint.
  - eventLoopGroup: SwiftNIO event loop group to use.
  - delegateDispatchQueue: `DispatchQueue` to use for dispatching calls to the delegate.

### `init(appId:projectId:prepareOnInit:sluClient:identityClient:cache:audioRecorder:delegateDispatchQueue:)`

Creates a new `SpeechClient`.

``` swift
public init(appId: UUID? = nil, projectId: UUID? = nil, prepareOnInit: Bool, sluClient: SluClientProtocol, identityClient: IdentityClientProtocol, cache: CacheProtocol, audioRecorder: AudioRecorderProtocol, delegateDispatchQueue: DispatchQueue) throws
```

#### Parameters

  - appId: Speechly application identifier. Eiither appId or projectId is needed.
  - projectId: Speechly projectt identifier. Eiither appId or projectId is needed.
  - prepareOnInit: Whether the client should prepare on initialisation. Preparing means initialising the audio stack and fetching the authentication token for the API.
  - sluClient: An implementation of a client for Speechly SLU API.
  - identityClient: An implementation of a client for Speechly Identity API.
  - cache: An implementation of a cache protocol.
  - audioRecorder: An implementaion of an audio recorder.
  - delegateDispatchQueue: `DispatchQueue` to use for dispatching calls to the delegate.

## Properties

### `delegate`

``` swift
var delegate: SpeechClientDelegate?
```

## Methods

### `audioRecorderDidStop(_:)`

``` swift
public func audioRecorderDidStop(_: AudioRecorderProtocol)
```

### `audioRecorderDidReceiveData(_:audioData:)`

``` swift
public func audioRecorderDidReceiveData(_: AudioRecorderProtocol, audioData: Data)
```

### `audioRecorderDidCatchError(_:error:)`

``` swift
public func audioRecorderDidCatchError(_: AudioRecorderProtocol, error: Error)
```

### `sluClientDidCatchError(_:error:)`

``` swift
public func sluClientDidCatchError(_ sluClient: SluClientProtocol, error: Error)
```

### `sluClientDidStopStream(_:status:)`

``` swift
public func sluClientDidStopStream(_ sluClient: SluClientProtocol, status: GRPCStatus)
```

### `sluClientDidReceiveContextStart(_:contextId:)`

``` swift
public func sluClientDidReceiveContextStart(_ sluClient: SluClientProtocol, contextId: String)
```

### `sluClientDidReceiveContextStop(_:contextId:)`

``` swift
public func sluClientDidReceiveContextStop(_ sluClient: SluClientProtocol, contextId: String)
```

### `sluClientDidReceiveTentativeTranscript(_:contextId:segmentId:transcript:)`

``` swift
public func sluClientDidReceiveTentativeTranscript(_ sluClient: SluClientProtocol, contextId: String, segmentId: Int, transcript: TentativeTranscript)
```

### `sluClientDidReceiveTentativeEntities(_:contextId:segmentId:entities:)`

``` swift
public func sluClientDidReceiveTentativeEntities(_ sluClient: SluClientProtocol, contextId: String, segmentId: Int, entities: TentativeEntities)
```

### `sluClientDidReceiveTentativeIntent(_:contextId:segmentId:intent:)`

``` swift
public func sluClientDidReceiveTentativeIntent(_ sluClient: SluClientProtocol, contextId: String, segmentId: Int, intent: TentativeIntent)
```

### `sluClientDidReceiveTranscript(_:contextId:segmentId:transcript:)`

``` swift
public func sluClientDidReceiveTranscript(_ sluClient: SluClientProtocol, contextId: String, segmentId: Int, transcript: Transcript)
```

### `sluClientDidReceiveEntity(_:contextId:segmentId:entity:)`

``` swift
public func sluClientDidReceiveEntity(_ sluClient: SluClientProtocol, contextId: String, segmentId: Int, entity: Entity)
```

### `sluClientDidReceiveIntent(_:contextId:segmentId:intent:)`

``` swift
public func sluClientDidReceiveIntent(_ sluClient: SluClientProtocol, contextId: String, segmentId: Int, intent: Intent)
```

### `sluClientDidReceiveSegmentEnd(_:contextId:segmentId:)`

``` swift
public func sluClientDidReceiveSegmentEnd(_ sluClient: SluClientProtocol, contextId: String, segmentId: Int)
```

### `start()`

``` swift
public func start()
```

### `stop()`

``` swift
public func stop()
```

### `suspend()`

``` swift
public func suspend()
```

### `resume()`

``` swift
public func resume() throws
```
