import Foundation
import AVFoundation
import Dispatch
import GRPC
import NIO

// MARK: - SpeechClient definition.

/// A client that implements `SpeechClientProtocol` on top of Speechly SLU API and an audio recorder.
///
/// The client handles both the audio and the API streams, as well as API authentication,
/// caching access tokens and dispatching data to delegate.
///
/// The client is ready to use once initialised.
public class SpeechClient {
    private let appId: UUID?
    private let projectId: UUID?
    private let appConfig: SluConfig
    private let cache: CacheProtocol
    private let identityClient: IdentityClientProtocol
    private var sluClient: SluClientProtocol
    private var audioRecorder: AudioRecorderProtocol

    private let delegateQueue: DispatchQueue
    private weak var delegateVal: SpeechClientDelegate?

    private let deviceIdKey = "deviceId"
    private var deviceIdValue: UUID? = nil
    private var deviceId: UUID {
        get {
            if deviceIdValue != nil {
                return deviceIdValue!
            }

            let generateId = { () -> UUID in
                let id = UUID()

                self.deviceIdValue = id
                self.cache.setValue(id.uuidString, forKey: self.deviceIdKey)

                return id
            }

            guard let cachedValue = cache.getValue(forKey: deviceIdKey) else {
                return generateId()
            }

            guard let cachedId = UUID(uuidString: cachedValue) else {
                return generateId()
            }

            self.deviceIdValue = cachedId
            return self.deviceIdValue!
        }
    }

    private struct SpeechContexts: Hashable {
        enum ContextError: Error {
            case alreadyExists, notFound
        }

        var speechContexts: [String:SpeechContext] = [:]

        func get(contextId: String) -> SpeechContext? {
            return self.speechContexts[contextId]
        }

        mutating func update(_ context: SpeechContext) {
            self.speechContexts[context.id] = context
        }

        mutating func add(contextId: String) throws -> SpeechContext {
            if self.get(contextId: contextId) != nil {
                throw ContextError.alreadyExists
            }

            let context = SpeechContext(id: contextId)
            self.speechContexts[contextId] = context

            return context
        }

        mutating func remove(contextId: String) throws -> SpeechContext {
            guard var context = self.speechContexts.removeValue(forKey: contextId) else {
                throw ContextError.notFound
            }

            return try context.finalise()
        }
    }

    private var contexts: SpeechContexts = SpeechContexts()

    /// Creates a new `SpeechClient`.
    ///
    /// - Parameters:
    ///     - appId: Speechly application identifier.
    ///     - language: Speechly application language.
    ///     - prepareOnInit: Whether the client should prepare on initialisation.
    ///                      Preparing means initialising the audio stack
    ///                      and fetching the authentication token for the API.
    ///     - identityAddr: The address of Speechly Identity gRPC service. Defaults to Speechly public API endpoint.
    ///     - sluAddr: The address of Speechly SLU gRPC service. Defaults to Speechly public API endpoint.
    ///     - eventLoopGroup: SwiftNIO event loop group to use.
    ///     - delegateDispatchQueue: `DispatchQueue` to use for dispatching calls to the delegate.
    public convenience init(
        appId: UUID?,
        projectId: UUID?,
        prepareOnInit: Bool = true,
        identityAddr: String = "grpc+tls://api.speechly.com",
        sluAddr: String = "grpc+tls://api.speechly.com",
        eventLoopGroup: EventLoopGroup = PlatformSupport.makeEventLoopGroup(loopCount: 1),
        delegateDispatchQueue: DispatchQueue = DispatchQueue(label: "com.speechly.iosclient.SpeechClient.delegateQueue")
    ) throws {
        let sluClient = try SluClient(addr: sluAddr, loopGroup: eventLoopGroup)
        let baseIdentityClient = try IdentityClient(addr: identityAddr, loopGroup: eventLoopGroup)
        let cache = UserDefaultsCache()
        let identityClient = CachingIdentityClient(baseClient: baseIdentityClient, cache: cache)
        let audioRecorder = try AudioRecorder(sampleRate: 16000, channels: 1, prepareOnInit: prepareOnInit)

        try self.init(
            appId: appId,
            projectId: projectId,
            prepareOnInit: prepareOnInit,
            sluClient: sluClient,
            identityClient: identityClient,
            cache: cache,
            audioRecorder: audioRecorder,
            delegateDispatchQueue: delegateDispatchQueue
        )
    }
    /// Creates a new `SpeechClient`.
    ///
    /// - Parameters:
    ///     - appId: Speechly application identifier.
    ///     - language: Speechly application language.
    ///     - prepareOnInit: Whether the client should prepare on initialisation.
    ///                      Preparing means initialising the audio stack
    ///                      and fetching the authentication token for the API.
    ///     - sluClient: An implementation of a client for Speechly SLU API.
    ///     - identityClient: An implementation of a client for Speechly Identity API.
    ///     - cache: An implementation of a cache protocol.
    ///     - audioRecorder: An implementaion of an audio recorder.
    ///     - delegateDispatchQueue: `DispatchQueue` to use for dispatching calls to the delegate.
    public init(
        appId: UUID?,
        projectId: UUID?,
        prepareOnInit: Bool,
        sluClient: SluClientProtocol,
        identityClient: IdentityClientProtocol,
        cache: CacheProtocol,
        audioRecorder: AudioRecorderProtocol,
        delegateDispatchQueue: DispatchQueue
    ) throws {
        self.appId = appId
        self.projectId = projectId
        self.sluClient = sluClient
        self.identityClient = identityClient
        self.cache = cache
        self.audioRecorder = audioRecorder
        self.delegateQueue = delegateDispatchQueue

        self.appConfig = SluConfig(
            sampleRate: audioRecorder.sampleRate,
            channels: audioRecorder.channels
        )

        self.sluClient.delegate = self
        self.audioRecorder.delegate = self

        if prepareOnInit {
            // Authenticate to API.
            // This will make sure that we have a valid token cached for the next `start` call.
            //
            // Otherwise the first real authentication call will happen during the first `start` call.
            //
            // Since we are using a caching implementation of identity client,
            // the call may or may not trigger a real RPC, depending on whether we have a cached valid token or not.
            let _ = try self.authenticate().wait()
        }
    }

    private func authenticate() -> EventLoopFuture<ApiAccessToken> {
        if let projectId = self.projectId {
            return self.identityClient.authenticateProject(projectId: projectId, deviceId: self.deviceId)
        }
        return self.identityClient.authenticate(appId: self.appId!, deviceId: self.deviceId)
    }
}

// MARK: - AudioRecorderDelegate protocol conformance.

extension SpeechClient: AudioRecorderDelegate {
    public func audioRecorderDidStop(_: AudioRecorderProtocol) {
        self.sluClient
            .stop()
            .whenFailure { error in
                self.delegateQueue.async {
                    self.delegate?.speechlyClientDidCatchError(self, error: .apiError(error.localizedDescription))
                }
            }
    }

    public func audioRecorderDidReceiveData(_: AudioRecorderProtocol, audioData: Data) {
        self.sluClient
            .write(data: audioData)
            .whenComplete { result in
                switch result {
                case let .failure(error):
                    self.delegateQueue.async {
                        self.delegate?.speechlyClientDidCatchError(self, error: .apiError(error.localizedDescription))
                    }
                case let .success(written):
                    if !written {
                        self.delegateQueue.async {
                            self.delegate?.speechlyClientDidCatchError(
                                self, error: .apiError("Attempted to send audio to closed SLU stream")
                            )
                        }
                    }
                }
            }
    }

    public func audioRecorderDidCatchError(_: AudioRecorderProtocol, error: Error) {
        self.delegateQueue.async {
            self.delegate?.speechlyClientDidCatchError(self, error: .audioError(error.localizedDescription))
        }
    }
}

// MARK: - SluClientDelegate protocol conformance.

extension SpeechClient: SluClientDelegate {
    public func sluClientDidCatchError(_ sluClient: SluClientProtocol, error: Error) {
        self.delegateQueue.async {
            self.delegate?.speechlyClientDidCatchError(self, error: .networkError(error.localizedDescription))
        }
    }

    public func sluClientDidStopStream(_ sluClient: SluClientProtocol, status: GRPCStatus) {
        self.delegateQueue.async {
            self.delegate?.speechlyClientDidStop(self)
        }

        if !status.isOk {
            self.delegateQueue.async {
                self.delegate?
                    .speechlyClientDidCatchError(self, error: .apiError(status.message ?? "Unknown API error"))
            }
        }
    }

    public func sluClientDidReceiveContextStart(_ sluClient: SluClientProtocol, contextId: String) {
        do {
            let _ = try self.contexts.add(contextId: contextId)
        } catch {
            self.delegateQueue.async {
                self.delegate?.speechlyClientDidCatchError(self, error: .parseError(error.localizedDescription))
            }
        }
    }

    public func sluClientDidReceiveContextStop(_ sluClient: SluClientProtocol, contextId: String) {
        do {
            let _ = try self.contexts.remove(contextId: contextId)
        } catch {
            self.delegateQueue.async {
                self.delegate?.speechlyClientDidCatchError(self, error: .parseError(error.localizedDescription))
            }
        }
    }

    public func sluClientDidReceiveTentativeTranscript(
        _ sluClient: SluClientProtocol, contextId: String, segmentId: Int, transcript: TentativeTranscript
    ) {
        self.updateContext(contextId, transform: { context in
            let transcripts = transcript.tentativeWords.map { w -> SpeechTranscript in
                let t = SpeechTranscript.parseProto(message: w, isFinal: false)

                self.delegateQueue.async {
                    self.delegate?
                        .speechlyClientDidReceiveTranscript(self, contextId: contextId, segmentId: segmentId, transcript: t)
                }

                return t
            }

            return try context.addTranscripts(transcripts, segmentId: segmentId)
        })
    }

    public func sluClientDidReceiveTentativeEntities(
        _ sluClient: SluClientProtocol, contextId: String, segmentId: Int, entities: TentativeEntities
    ) {
        self.updateContext(contextId, transform: { context in
            let entities = entities.tentativeEntities.map { e -> SpeechEntity in
                let entity = SpeechEntity.parseProto(message: e, isFinal: false)

                self.delegateQueue.async {
                    self.delegate?
                        .speechlyClientDidReceiveEntity(self, contextId: contextId, segmentId: segmentId, entity: entity)
                }

                return entity
            }

            return try context.addEntities(entities, segmentId: segmentId)
        })
    }

    public func sluClientDidReceiveTentativeIntent(
        _ sluClient: SluClientProtocol, contextId: String, segmentId: Int, intent: TentativeIntent
    ) {
        self.updateContext(contextId, transform: { context in
            let intent = SpeechIntent.parseProto(message: intent, isFinal: false)

            self.delegateQueue.async {
                self.delegate?
                    .speechlyClientDidReceiveIntent(self, contextId: contextId, segmentId: segmentId, intent: intent)
            }

            return try context.addIntent(intent, segmentId: segmentId)
        })
    }

    public func sluClientDidReceiveTranscript(
        _ sluClient: SluClientProtocol, contextId: String, segmentId: Int, transcript: Transcript
    ) {
        self.updateContext(contextId, transform: { context in
            let transcript = SpeechTranscript.parseProto(message: transcript, isFinal: true)

            self.delegateQueue.async {
                self.delegate?
                    .speechlyClientDidReceiveTranscript(self, contextId: contextId, segmentId: segmentId, transcript: transcript)
            }

            return try context.addTranscripts([transcript], segmentId: segmentId)
        })
    }

    public func sluClientDidReceiveEntity(
        _ sluClient: SluClientProtocol, contextId: String, segmentId: Int, entity: Entity
    ) {
        self.updateContext(contextId, transform: { context in
            let entity = SpeechEntity.parseProto(message: entity, isFinal: true)

            self.delegateQueue.async {
                self.delegate?
                    .speechlyClientDidReceiveEntity(self, contextId: contextId, segmentId: segmentId, entity: entity)
            }

            return try context.addEntities([entity], segmentId: segmentId)
        })
    }

    public func sluClientDidReceiveIntent(
        _ sluClient: SluClientProtocol, contextId: String, segmentId: Int, intent: Intent
    ) {
        self.updateContext(contextId, transform: { context in
            let intent = SpeechIntent.parseProto(message: intent, isFinal: true)

            self.delegateQueue.async {
                self.delegate?
                    .speechlyClientDidReceiveIntent(self, contextId: contextId, segmentId: segmentId, intent: intent)
            }

            return try context.addIntent(intent, segmentId: segmentId)
        })
    }

    public func sluClientDidReceiveSegmentEnd(_ sluClient: SluClientProtocol, contextId: String, segmentId: Int) {
        self.updateContext(contextId, transform: { context in
            return try context.finaliseSegment(segmentId: segmentId)
        })
    }

    /// This method fetches a context from local cache,
    /// passes it to the closure for evaluation / mutation
    /// and then updates it back to the cache.
    ///
    /// It will dispatch the segment returned by the closure to the delegate.
    /// It will also dispatch caught errors to the delegate.
    private func updateContext(_ id: String, transform: (inout SpeechContext) throws -> SpeechSegment) {
        guard var context = self.contexts.get(contextId: id) else {
            self.delegateQueue.async {
                self.delegate?
                    .speechlyClientDidCatchError(self, error: .parseError("Received response for unknown context"))
            }

            return
        }

        let segment: SpeechSegment
        do {
            segment = try transform(&context)
        } catch {
            self.delegateQueue.async {
                self.delegate?.speechlyClientDidCatchError(self, error: .parseError(error.localizedDescription))
            }

            return
        }

        self.delegateQueue.async {
            self.delegate?.speechlyClientDidUpdateSegment(self, segment: segment)
        }

        self.contexts.update(context)
    }
}

// MARK: - SpeechlyClientProtocol protocol conformance.

extension SpeechClient: SpeechClientProtocol {
    public weak var delegate: SpeechClientDelegate? {
        get {
            return self.delegateVal
        }

        set(newDelegate) {
            self.delegateQueue.sync(flags: .barrier) {
                self.delegateVal = newDelegate
            }
        }
    }

    public func start() {
        self
            .authenticate()
            .flatMap { token in
                self.sluClient.start(token: token, config: self.appConfig)
            }
            .flatMapThrowing {
                try self.audioRecorder.start()
            }
            .whenComplete { result in
                switch result {
                case .success:
                    self.delegateQueue.async {
                        self.delegate?.speechlyClientDidStart(self)
                    }
                case let .failure(error):
                    self.delegateQueue.async {
                        // TODO: this will mix API errors and audio recorder errors together.
                        // We should change the error handling so that we can distinguish between the two.
                        self.delegate?
                            .speechlyClientDidCatchError(self, error: .networkError(error.localizedDescription))
                    }
                }
            }
    }

    public func stop() {
        self.audioRecorder.stop()
    }

    public func suspend() {
        do {
            try self.audioRecorder.suspend()
        } catch {
            print("Error suspending audio recorder", error)
        }

        do {
            try self.sluClient.suspend().wait()
        } catch {
            print("Error suspending API client", error)
        }
    }

    public func resume() throws {
        try self
            .sluClient.resume()
            .flatMapThrowing {
                try self.audioRecorder.resume()
            }
            .wait()
    }
}
