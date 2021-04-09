# Types

  - [AudioRecorder](AudioRecorder.md):
    An audio recorder implementation that uses AVFoundation audio engine for capturing the input.
  - [AudioRecorder.AudioRecorderError](AudioRecorder_AudioRecorderError.md):
    Errors thrown by the audio recorder.
  - [AudioContext](AudioContext.md):
    The speech recognition context.
  - [UserDefaultsCache](UserDefaultsCache.md):
    A cache implementation that uses `UserDefaults` as the backing storage.
  - [Client](Client.md):
    A client that implements `SpeechClientProtocol` on top of Speechly SLU API and an audio recorder.
  - [Client.SpeechlyClientInitError](Client_SpeechlyClientInitError.md):
    Represents different error situations when initializing the SpeechlyClient.
  - [Entity](Entity.md):
    A speech entity.
  - [Entity.ID](Entity_ID.md):
    A custom ID implementation for `SpeechEntity`.
    Since entities have two indices, start and end,
    this struct encapsulates the two for indexing and sorting purposes.
  - [GRPCAddress](GRPCAddress.md):
    A gRPC service address.
  - [GRPCAddress.ParseError](GRPCAddress_ParseError.md):
    Errors thrown when parsing the address.
  - [ApiAccessToken](ApiAccessToken.md):
    A struct representing an access token returned by Speechly Identity service.
  - [ApiAccessToken.AuthScope](ApiAccessToken_AuthScope.md):
    Token authorisation scopes.
    They determine which services can be accessed with this token.
  - [ApiAccessToken.TokenType](ApiAccessToken_TokenType.md):
    Type of token, determines the possible Speechly Apps that are accessible.
  - [CachingIdentityClient](CachingIdentityClient.md):
    A client for Speechly Identity gRPC API which provides token caching functionality.
  - [IdentityClient](IdentityClient.md):
    A client for Speechly Identity gRPC API.
  - [IdentityClient.IdentityClientError](IdentityClient_IdentityClientError.md):
    Errors returned by the client.
  - [Intent](Intent.md):
    A speech intent.
  - [InvalidSLUState](InvalidSLUState.md):
    Possible invalid states of the client, eg. if `startContext` is called without connecting to API first.
  - [SluClient](SluClient.md):
    An SluClientProtocol that is implemented on top of public Speechly SLU gRPC API.
    Uses `swift-grpc` for handling gRPC streams and connectivity.
  - [SluConfig](SluConfig.md):
    SLU stream configuration describes the audio data sent to the stream.
    If misconfigured, the recognition stream will not produce any useful results.
  - [Segment](Segment.md):
    A segment is a part of a recognition context (or a phrase) which is defined by an intent.
  - [SpeechlyError](SpeechlyError.md):
    Errors caught by `SpeechClientProtocol` and dispatched to `SpeechClientDelegate`.
  - [Transcript](Transcript.md):
    A speech transcript.
  - [MicrophoneButtonView](MicrophoneButtonView.md)
  - [SpeechBubbleView](SpeechBubbleView.md)
  - [TranscriptView](TranscriptView.md)

# Protocols

  - [AudioRecorderProtocol](AudioRecorderProtocol.md):
    A protocol for capturing audio data from input sources (microphones).
  - [AudioRecorderDelegate](AudioRecorderDelegate.md):
    Delegate called when audio recorder receives some data or an error, or when it has been stopped.
  - [CacheProtocol](CacheProtocol.md):
    A protocol for a cache storage.
  - [Promisable](Promisable.md):
    A protocol that defines methods for making succeeded and failed futures.
  - [IdentityClientProtocol](IdentityClientProtocol.md):
    Protocol that defines a client for Speechly Identity API.
  - [SluClientProtocol](SluClientProtocol.md):
    A protocol defining a client for Speechly SLU API.
  - [SluClientDelegate](SluClientDelegate.md):
    Delegate called when an SLU client receives messages from the API or catches an error.
    The intended use of this protocol is with `SluClientProtocol`.
  - [SpeechlyProtocol](SpeechlyProtocol.md):
    A speech client protocol.
  - [SpeechlyDelegate](SpeechlyDelegate.md):
    Delegate called when a speech client handles messages from the API or catches an error.
  - [MicrophoneButtonDelegate](MicrophoneButtonDelegate.md)

# Global Functions

  - [makeChannel(addr:​loopCount:​)](makeChannel\(addr:loopCount:\).md):
    A function that creates a new gRPC channel for the provided address.
    It will also create a NIO eventloop group with the specified loop count.
  - [makeChannel(addr:​group:​)](makeChannel\(addr:group:\).md):
    A function that creates a new gRPC channel for the provided address.
  - [makeTokenCallOptions(token:​)](makeTokenCallOptions\(token:\).md):
    A function that creates new gRPC call options (metadata) that contains an authorisation token.
