import Foundation
import Dispatch
import GRPC
import NIO
import SpeechlyAPI

// MARK: - SLU service definition.

/// An SluClientProtocol that is implemented on top of public Speechly SLU gRPC API.
/// Uses `swift-grpc` for handling gRPC streams and connectivity.
public class SluClient {
    private enum State {
        case idle
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
            switch self.state {
            case let .streaming(stream):
                // Close the stream from the client side.
                try self.stopStream(stream: stream).wait()

                // Wait until the stream is closed from the server side.
                let status = try stream.status.wait()
                print("SLU stream stopped with status:", status.description)
            default:
                break
            }
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

    public func start(token: ApiAccessToken, config: SluConfig, appId: String? = nil) -> EventLoopFuture<Void> {
        let future: EventLoopFuture<SluStream>

        switch self.state {
        case let .streaming(stream):
            future = self
                .stopStream(stream: stream)
                .flatMap {
                    self.makeStream(token: token, config: config, appId: appId)
                }
        case .idle:
            future = self.makeStream(token: token, config: config, appId: appId)
        }

        return future.map { stream in
            self.state = .streaming(stream)
        }
    }

    public func stop() -> EventLoopFuture<Void> {
        switch self.state {
        case let .streaming(stream):
            return self
                .stopStream(stream: stream)
                .map {
                    self.state = .idle
                }
        case .idle:
            return self.group.next().makeSucceededFuture(Void())
        }
    }

    public func resume() -> EventLoopFuture<Void> {
        // Resume logic is basically the same as suspend.
        // If there is somehow still an active stream, discard it, because it's most likely corrupted.
        return self.suspend()
    }

    public func suspend() -> EventLoopFuture<Void> {
        switch self.state {
        case let .streaming(stream):
            // Make a promise that's passed to stream.cancel().
            let promise = self.group.next().makePromise(of: Void.self)

            // Once stream is canceled, we want to wait until the server closes the stream from its end.
            let future = promise.futureResult.flatMap {
                stream.status
            }

            // Cancel the stream.
            stream.cancel(promise: promise)

            // Discard the status.
            return future.map { _ in
                return
            }
        case .idle:
            return self.group.next().makeSucceededFuture(Void())
        }
    }

    public func write(data: Data) -> EventLoopFuture<Bool> {
        switch self.state {
        case let .streaming(stream):
            return stream
                .sendMessage(SluRequestProto.with {
                    $0.audio = data
                })
                .map { true }
        case .idle:
            return self.group.next().makeSucceededFuture(false)
        }
    }

    private typealias SluConfigProto = Speechly_Slu_V1_SLUConfig
    private typealias SluEventProto = Speechly_Slu_V1_SLUEvent

    private func makeStream(token: ApiAccessToken, config: SluConfig, appId: String?) -> EventLoopFuture<SluStream> {
        var callOptions = makeTokenCallOptions(token: token.tokenString)
        callOptions.requestIDHeader = UUID.init().uuidString

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

            switch self.state {
            case let .streaming(stateStream):
                if stream.options.requestIDHeader != nil &&
                   stream.options.requestIDHeader == stateStream.options.requestIDHeader {
                    self.state = .idle
                }
            default:
                return
            }
        }

        return stream
            .sendMessage(SluRequestProto.with {
                $0.config = SluConfigProto.with {
                    $0.encoding = .linear16
                    $0.sampleRateHertz = Int32(config.sampleRate)
                    $0.channels = Int32(config.channels)
                }
            })
            .flatMap {
               stream.sendMessage(SluRequestProto.with {
                   $0.event = SluEventProto.with {
                       $0.event = .start
                       $0.appID = appId ?? ""
                   }
               })
            }
            .map { stream }
    }

    private func stopStream(stream: SluStream) -> EventLoopFuture<Void> {
        return stream
            .sendMessage(SluRequestProto.with {
                $0.event = SluEventProto.with {
                    $0.event = .stop
                }
            })
            .flatMap {
                stream.status
            }
            .map { _ in
                return
            }
    }

    private func handleResponse(response: SluResponseProto) -> Void {
        self.delegateQueue.async {
            let contextId = response.audioContext
            let segmentId = Int(response.segmentID)

            switch(response.streamingResponse) {
            case .started:
                self.delegate?.sluClientDidReceiveContextStart(self, contextId: contextId)
            case .finished:
                // Currently we only close the stream after receiving context stop message.
                // This is not ideal, but it's the only way to drain the stream.
                // TODO: figure out a nicer way to handle stream closures.
                switch self.state {
                case let .streaming(stream):
                    stream.sendEnd(promise: nil)
                default:
                    break
                }

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
