import Foundation
import Dispatch
import GRPC
import NIO
import SpeechlyAPI
import os.log

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
    
    typealias DisconnectTimer = DispatchWorkItem

    private enum State {
        case idle
        case connected(DisconnectTimer, SluStream)
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
            os_log("SLU stream disconnect failed: %@", log: speechly, type: .error, String(describing: error))
        }

        do {
            try self.client.channel.close().wait()
        } catch {
            os_log("gRPC channel close failed: %@", log: speechly, type: .error, String(describing: error))
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
        switch self.state {
        case .streaming, .connected(_, _):
            return self.group.next().makeSucceededVoidFuture()
        case .idle:
            return self.makeStream(token: token, config: config)
                .map { (timer, stream) in
                    self.state = .connected(timer, stream)
                }
        }
    }
    
    public func disconnect() -> EventLoopFuture<Void> {
        switch self.state {
        case .streaming(let stream):
            return self.stopContext()
                .flatMap { self.stopStream(stream: stream) }
                .map { _ in
                    return
                }
        case .connected(let timer, let stream):
            return self.stopStream(stream: stream)
                .map { _ in
                    timer.cancel()
                    return
                }
        case .idle:
            return self.group.next().makeSucceededVoidFuture()
        }
    }
    
    public func startContext(appId: String? = nil) -> EventLoopFuture<Void> {
        switch self.state {
        case .idle:
            return self.group.next().makeFailedFuture(InvalidSLUState.notConnected)
        case .streaming(_):
            return self.group.next().makeFailedFuture(InvalidSLUState.contextAlreadyStarted)
        case let .connected(timer, stream):
            timer.cancel()
            return stream.sendMessage(SluRequestProto.with {
                $0.start = SluStartProto.with {
                    $0.appID = appId ?? ""
                    $0.options = [SluStartOptionProto.with {
                        $0.key = "timezone"
                        $0.value = [TimeZone.current.identifier]
                    }]
                }
            })
            .map {
                self.state = .streaming(stream)
            }
        }
    }

    public func stopContext() -> EventLoopFuture<Void> {
        switch self.state {
        case .idle:
            return self.group.next().makeFailedFuture(InvalidSLUState.notConnected)
        case .connected(_, _):
            return self.group.next().makeFailedFuture(InvalidSLUState.contextNotStarted)
        case let .streaming(stream):
            return stream
                .sendMessage(SluRequestProto.with {
                    $0.stop = SluStopProto()
                })
                .map {
                    self.state = .connected(self.makeDisconnectTimer(), stream)
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
        case .connected(_, _):
            return self.group.next().makeFailedFuture(InvalidSLUState.contextNotStarted)
        case let .streaming(stream):
            return stream
                .sendMessage(SluRequestProto.with {
                    $0.audio = data
                })
        }
    }

    private typealias SluConfigProto = Speechly_Slu_V1_SLUConfig
    private typealias SluStartProto = Speechly_Slu_V1_SLUStart
    private typealias SluStopProto = Speechly_Slu_V1_SLUStop
    private typealias SluStartOptionProto = Speechly_Slu_V1_SLUStart.Option

    private func makeStream(token: ApiAccessToken, config: SluConfig) -> EventLoopFuture<(DisconnectTimer, SluStream)> {
        os_log("Connecting to SLU API", log: speechly, type: .debug)
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
                return (self.makeDisconnectTimer(), stream)
            }
    }

    private func makeDisconnectTimer() -> DisconnectTimer {
        let task = DispatchWorkItem {
            do {
                try self.disconnect().wait()
            } catch {
                os_log("Disconnect stream failed: %@", log: speechly, type: .error, String(describing: error))
            }
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 30, execute: task)
        return task
    }
    
    private func stopStream(stream: SluStream) -> EventLoopFuture<GRPCStatus> {
        os_log("Disconnect SLU stream", log: speechly, type: .debug)
        // Make a promise that's passed to stream.cancel().
        let promise = self.group.next().makePromise(of: Void.self)

        // Once stream is canceled, we want to wait until the server closes the stream from its end.
        let future: EventLoopFuture<GRPCStatus> = promise.futureResult
            .flatMap {
                self.state = .idle
                return stream.status
            }

        stream.sendEnd(promise: promise)
        // Cancel the stream.
        //stream.cancel(promise: promise)
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
