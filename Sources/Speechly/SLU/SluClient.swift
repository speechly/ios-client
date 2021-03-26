import Foundation
import Dispatch
import GRPC
import NIO
import SpeechlyAPI

// MARK: - SLU service definition.

/// Possible invalid states of the client, eg. if `startContext` is called without connecting to API first.
public enum InvalidSLUState: Error {
    case notConnected
    case contextAlreadyStarted
    case contextNotStarted
}

/// An SluClientProtocol that is implemented on top of public Speechly SLU gRPC API.
/// Uses `swift-grpc` for handling gRPC streams and connectivity.
public class SluClient {
    private enum State {
        case idle
        case connected(SluStream)
        case streaming(SluStream)
    }

    private var state: State = .idle
    private let group: EventLoopGroup
    private let client: SluApiClient

    private let delegateQueue: DispatchQueue
    private weak var _delegate: SluClientDelegate? = nil

    /// Creates a new client.
    ///
    /// - Parameters:
    ///     - addr: The address of Speechly SLU API to connect to.
    ///     - loopGroup: The `NIO.EventLoopGroup` to use in the client.
    ///     - delegateQueue: The `DispatchQueue` to use for calling the delegate.
    public convenience init(
        addr: String,
        loopGroup: EventLoopGroup,
        delegateQueue: DispatchQueue = DispatchQueue(label: "com.speechly.iosclient.SluClient.delegateQueue")
    ) throws {
        let channel = try makeChannel(addr: addr, group: loopGroup)
        let client = Speechly_Slu_V1_SLUClient(channel: channel)

        self.init(client: client, group: loopGroup, delegateQueue: delegateQueue)
    }

    /// An alias for Speechly SLU client protocol.
    public typealias SluApiClient = Speechly_Slu_V1_SLUClientProtocol

    /// Creates a new client.
    ///
    /// - Parameters:
    ///     - client: The `SluApiClient` to use for creating SLU streams.
    ///     - group: The `NIO.EventLoopGroup` to use in the client.
    ///     - delegateQueue: The `DispatchQueue` to use for calling the delegate.
    public init(client: SluApiClient, group: EventLoopGroup, delegateQueue: DispatchQueue) {
        self.client = client
        self.group = group
        self.delegateQueue = delegateQueue
    }

    deinit {
        do {
            try self.disconnect().wait()
        } catch {
            print("Error stopping SLU stream:", error)
        }

        do {
            try self.client.channel.close().wait()
        } catch {
            print("Error closing gRPC channel:", error)
        }
    }
}

// MARK: - SluClientProtocol conformance.

extension SluClient: SluClientProtocol {
    public weak var delegate: SluClientDelegate? {
        get {
            return self._delegate
        }

        set(newDelegate) {
            self.delegateQueue.sync(flags: .barrier) {
                self._delegate = newDelegate
            }
        }
    }

    private typealias SluStream = BidirectionalStreamingCall<SluRequestProto, SluResponseProto>
    private typealias SluRequestProto = Speechly_Slu_V1_SLURequest
    private typealias SluResponseProto = Speechly_Slu_V1_SLUResponse

    public func connect(token: ApiAccessToken, config: SluConfig) -> EventLoopFuture<Void> {
        print("sluClient.connect, state: \(self.state)")
        switch self.state {
        case .streaming, .connected(_):
            return self.group.next().makeSucceededVoidFuture()
        case .idle:
            return self.makeStream(token: token, config: config)
                .map { stream in
                    self.state = .connected(stream)
                }
        }
    }
    
    public func disconnect() -> EventLoopFuture<Void> {
        print("sluClient.disconnect, state: \(self.state)")
        switch self.state {
        case .streaming(let stream):
            return self.stopContext()
                .flatMap { self.stopStream(stream: stream) }
                .map { _ in
                    return
                }
        case .connected(let stream):
            return self.stopStream(stream: stream)
                .map { _ in
                    return
                }
        case .idle:
            return self.group.next().makeSucceededVoidFuture()
        }
    }
    
    public func startContext(appId: String? = nil) -> EventLoopFuture<Void> {
        print("sluClient.startContext, state: \(self.state)")
        switch self.state {
        case .idle:
            return self.group.next().makeFailedFuture(InvalidSLUState.notConnected)
        case .streaming(_):
            print("returning aan error, sttreaming!")
            return self.group.next().makeFailedFuture(InvalidSLUState.contextAlreadyStarted)
        case let .connected(stream):
            return stream.sendMessage(SluRequestProto.with {
                $0.event = SluEventProto.with {
                    $0.event = .start
                    $0.appID = appId ?? ""
                }
            })
            .map {
                self.state = .streaming(stream)
            }
        }
    }

    public func stopContext() -> EventLoopFuture<Void> {
        print("sluClient.stopContext, state: \(self.state)")
        switch self.state {
        case .idle:
            return self.group.next().makeFailedFuture(InvalidSLUState.notConnected)
        case .connected(_):
            return self.group.next().makeFailedFuture(InvalidSLUState.contextNotStarted)
        case let .streaming(stream):
            return stream
                .sendMessage(SluRequestProto.with {
                    $0.event = SluEventProto.with {
                        $0.event = .stop
                    }
                })
                .map {
                    self.state = .connected(stream)
                }
        }
    }

    public func resume() -> EventLoopFuture<Void> {
        // If there is somehow still an active stream, discard it, because it's most likely corrupted.
        return self.disconnect()
    }

    public func suspend() -> EventLoopFuture<Void> {
        return self.disconnect()
    }

    public func write(data: Data) -> EventLoopFuture<Void> {
        switch self.state {
        case .idle:
            return self.group.next().makeFailedFuture(InvalidSLUState.notConnected)
        case .connected(_):
            return self.group.next().makeFailedFuture(InvalidSLUState.contextNotStarted)
        case let .streaming(stream):
            return stream
                .sendMessage(SluRequestProto.with {
                    $0.audio = data
                })
        }
    }

    private typealias SluConfigProto = Speechly_Slu_V1_SLUConfig
    private typealias SluEventProto = Speechly_Slu_V1_SLUEvent

    private func makeStream(token: ApiAccessToken, config: SluConfig) -> EventLoopFuture<SluStream> {
        let callOptions = makeTokenCallOptions(token: token.tokenString)

        let stream = self.client.stream(
            callOptions: callOptions,
            handler: { response in self.handleResponse(response: response) }
        )

        stream.status.whenComplete { result in
            switch result {
            case let .failure(error):
                self.delegateQueue.async {
                    self.delegate?.sluClientDidCatchError(self, error: error)
                }
            case let .success(status):
                self.delegateQueue.async {
                    self.delegate?.sluClientDidStopStream(self, status: status)
                }
            }
            self.state = .idle
        }

        return stream
            .sendMessage(SluRequestProto.with {
                $0.config = SluConfigProto.with {
                    $0.encoding = .linear16
                    $0.sampleRateHertz = Int32(config.sampleRate)
                    $0.channels = Int32(config.channels)
                }
            })
            .map {
                return stream
            }
    }

    private func stopStream(stream: SluStream) -> EventLoopFuture<GRPCStatus> {
        // Make a promise that's passed to stream.cancel().
        let promise = self.group.next().makePromise(of: Void.self)

        // Once stream is canceled, we want to wait until the server closes the stream from its end.
        let future: EventLoopFuture<GRPCStatus> = promise.futureResult
            .flatMap {
                self.state = .idle
                return stream.status
            }

        // Cancel the stream.
        stream.cancel(promise: promise)
        return future
    }

    private func handleResponse(response: SluResponseProto) -> Void {
        self.delegateQueue.async {
            let contextId = response.audioContext
            let segmentId = Int(response.segmentID)

            switch(response.streamingResponse) {
            case .started:
                self.delegate?.sluClientDidReceiveContextStart(self, contextId: contextId)
            case .finished:
                self.delegate?.sluClientDidReceiveContextStop(self, contextId: contextId)
            case let .tentativeTranscript(transcript):
                self.delegate?.sluClientDidReceiveTentativeTranscript(
                    self, contextId: contextId, segmentId: segmentId, transcript: transcript
                )
            case let .tentativeEntities(entities):
                self.delegate?.sluClientDidReceiveTentativeEntities(
                    self, contextId: contextId, segmentId: segmentId, entities: entities
                )
            case let .tentativeIntent(intent):
                self.delegate?.sluClientDidReceiveTentativeIntent(
                    self, contextId: contextId, segmentId: segmentId, intent: intent
                )
            case let .transcript(transcript):
                self.delegate?.sluClientDidReceiveTranscript(
                    self, contextId: contextId, segmentId: segmentId, transcript: transcript
                )
            case let .entity(entity):
                self.delegate?.sluClientDidReceiveEntity(
                    self, contextId: contextId, segmentId: segmentId, entity: entity
                )
            case let .intent(intent):
                self.delegate?.sluClientDidReceiveIntent(
                    self, contextId: contextId, segmentId: segmentId, intent: intent
                )
            case .segmentEnd:
                self.delegate?.sluClientDidReceiveSegmentEnd(self, contextId: contextId, segmentId: segmentId)
            default:
                return
            }
        }
    }
}
