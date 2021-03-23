# Types

  - [AudioRecorder](AudioRecorder):
    An audio recorder implementation that uses AVFoundation audio engine for capturing the input.
  - [AudioRecorder.AudioRecorderError](AudioRecorder_AudioRecorderError):
    Errors thrown by the audio recorder.
  - [UserDefaultsCache](UserDefaultsCache):
    A cache implementation that uses `UserDefaults` as the backing storage.
  - [GRPCAddress](GRPCAddress):
    A gRPC service address.
  - [GRPCAddress.ParseError](GRPCAddress_ParseError):
    Errors thrown when parsing the address.
  - [ApiAccessToken](ApiAccessToken):
    A struct representing an access token returned by Speechly Identity service.
  - [ApiAccessToken.AuthScope](ApiAccessToken_AuthScope):
    Token authorisation scopes.
    They determine which services can be accessed with this token.
  - [ApiAccessToken.TokenType](ApiAccessToken_TokenType):
    Type of token, determines the possible Speechly Apps that are accessible.
  - [CachingIdentityClient](CachingIdentityClient):
    A client for Speechly Identity gRPC API which provides token caching functionality.
  - [IdentityClient](IdentityClient):
    A client for Speechly Identity gRPC API.
  - [IdentityClient.IdentityClientError](IdentityClient_IdentityClientError):
    Errors returned by the client.
  - [SluClient](SluClient):
    An SluClientProtocol that is implemented on top of public Speechly SLU gRPC API.
    Uses `swift-grpc` for handling gRPC streams and connectivity.
  - [SluConfig](SluConfig):
    SLU stream configuration describes the audio data sent to the stream.
    If misconfigured, the recognition stream will not produce any useful results.
  - [SpeechClient](SpeechClient):
    A client that implements `SpeechClientProtocol` on top of Speechly SLU API and an audio recorder.
  - [SpeechClientError](SpeechClientError):
    Errors caught by `SpeechClientProtocol` and dispatched to `SpeechClientDelegate`.
  - [SpeechContext](SpeechContext):
    The speech recognition context.
  - [SpeechEntity](SpeechEntity):
    A speech entity.
  - [SpeechEntity.ID](SpeechEntity_ID):
    A custom ID implementation for `SpeechEntity`.
    Since entities have two indices, start and end,
    this struct encapsulates the two for indexing and sorting purposes.
  - [SpeechIntent](SpeechIntent):
    A speech intent.
  - [SpeechSegment](SpeechSegment):
    A segment is a part of a recognition context (or a phrase) which is defined by an intent.
  - [SpeechTranscript](SpeechTranscript):
    A speech transcript.

# Protocols

  - [AudioRecorderProtocol](AudioRecorderProtocol):
    A protocol for capturing audio data from input sources (microphones).
  - [AudioRecorderDelegate](AudioRecorderDelegate):
    Delegate called when audio recorder receives some data or an error, or when it has been stopped.
  - [CacheProtocol](CacheProtocol):
    A protocol for a cache storage.
  - [Promisable](Promisable):
    A protocol that defines methods for making succeeded and failed futures.
  - [IdentityClientProtocol](IdentityClientProtocol):
    Protocol that defines a client for Speechly Identity API.
  - [SluClientProtocol](SluClientProtocol):
    A protocol defining a client for Speechly SLU API.
  - [SluClientDelegate](SluClientDelegate):
    Delegate called when an SLU client receives messages from the API or catches an error.
    The intended use of this protocol is with `SluClientProtocol`.
  - [SpeechClientProtocol](SpeechClientProtocol):
    A speech client protocol.
  - [SpeechClientDelegate](SpeechClientDelegate):
    Delegate called when a speech client handles messages from the API or catches an error.

# Global Functions

  - [makeChannel(addr:​loopCount:​)](makeChannel\(addr:loopCount:\)):
    A function that creates a new gRPC channel for the provided address.
    It will also create a NIO eventloop group with the specified loop count.
  - [makeChannel(addr:​group:​)](makeChannel\(addr:group:\)):
    A function that creates a new gRPC channel for the provided address.
  - [makeTokenCallOptions(token:​)](makeTokenCallOptions\(token:\)):
    A function that creates new gRPC call options (metadata) that contains an authorisation token.
