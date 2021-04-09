import Foundation
import AVFoundation
import Dispatch
import GRPC
import NIO
import os.log

let speechly = OSLog(subsystem: "com.speechly.client", category: "speechly")

// MARK: - SpeechClient definition.

/// A client that implements `SpeechClientProtocol` on top of Speechly SLU API and an audio recorder.
///
/// The client handles both the audio and the API streams, as well as API authentication,
/// caching access tokens and dispatching data to delegate.
///
/// The client is ready to use once initialised.
public class Client {
    private let appId: UUID?
    private let projectId: UUID?
    private let appConfig: SluConfig
    private let cache: CacheProtocol
    private let identityClient: IdentityClientProtocol
    private var sluClient: SluClientProtocol
    private var audioRecorder: AudioRecorderProtocol

    private let delegateQueue: DispatchQueue
    private weak var delegateVal: SpeechlyDelegate?

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

        var speechContexts: [String:AudioContext] = [:]

        func get(contextId: String) -> AudioContext? {
            return self.speechContexts[contextId]
        }

        mutating func update(_ context: AudioContext) {
            self.speechContexts[context.id] = context
        }

        mutating func add(contextId: String) throws -> AudioContext {
            if self.get(contextId: contextId) != nil {
                throw ContextError.alreadyExists
            }

            let context = AudioContext(id: contextId)
            self.speechContexts[contextId] = context

            return context
        }

        mutating func remove(contextId: String) throws -> AudioContext {
            guard var context = self.speechContexts.removeValue(forKey: contextId) else {
                throw ContextError.notFound
            }

            return try context.finalise()
        }
    }

    private var contexts: SpeechContexts = SpeechContexts()

    /// Represents different error situations when initializing the SpeechlyClient.
    public enum SpeechlyClientInitError: Error {
        /// no appId or projectId given.
        case keysMissing
    }
    
    /// Creates a new `SpeechClient`.
    ///
    /// - Parameters:
    ///     - appId: Speechly application identifier. Eiither appId or projectId is needed.
    ///     - projectId: Speechly projectt identifier. Eiither appId or projectId is needed.
    ///     - prepareOnInit: Whether the client should prepare on initialisation.
    ///                      Preparing means initialising the audio stack
    ///                      and fetching the authentication token for the API.
    ///     - identityAddr: The address of Speechly Identity gRPC service. Defaults to Speechly public API endpoint.
    ///     - sluAddr: The address of Speechly SLU gRPC service. Defaults to Speechly public API endpoint.
    ///     - eventLoopGroup: SwiftNIO event loop group to use.
    ///     - delegateDispatchQueue: `DispatchQueue` to use for dispatching calls to the delegate.
    public convenience init(
        appId: UUID? = nil,
        projectId: UUID? = nil,
        prepareOnInit: Bool = true,
        identityAddr: String = "grpc+tls://api.speechly.com",
        sluAddr: String = "grpc+tls://api.speechly.com",
        eventLoopGroup: EventLoopGroup = PlatformSupport.makeEventLoopGroup(loopCount: 1),
        delegateDispatchQueue: DispatchQueue = DispatchQueue(label: "com.speechly.Client.delegateQueue")
    ) throws {
        if appId == nil && projectId == nil {
            throw SpeechlyClientInitError.keysMissing
        }
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
    ///     - appId: Speechly application identifier. Eiither appId or projectId is needed.
    ///     - projectId: Speechly projectt identifier. Eiither appId or projectId is needed.
    ///     - prepareOnInit: Whether the client should prepare on initialisation.
    ///                      Preparing means initialising the audio stack
    ///                      and fetching the authentication token for the API.
    ///     - sluClient: An implementation of a client for Speechly SLU API.
    ///     - identityClient: An implementation of a client for Speechly Identity API.
    ///     - cache: An implementation of a cache protocol.
    ///     - audioRecorder: An implementaion of an audio recorder.
    ///     - delegateDispatchQueue: `DispatchQueue` to use for dispatching calls to the delegate.
    public init(
        appId: UUID? = nil,
        projectId: UUID? = nil,
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

extension Client: AudioRecorderDelegate {
    public func audioRecorderDidStop(_: AudioRecorderProtocol) {
        self.sluClient
            .stopContext()
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
                if case .failure(let error) = result {
                    self.delegateQueue.async {
                        self.delegate?.speechlyClientDidCatchError(self, error: .apiError(error.localizedDescription))
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

extension Client: SluClientDelegate {
    public func sluClientDidCatchError(_ sluClient: SluClientProtocol, error: Error) {
        self.delegateQueue.async {
            self.delegate?.speechlyClientDidCatchError(self, error: .networkError(error.localizedDescription))
        }
    }

    public func sluClientDidStopStream(_ sluClient: SluClientProtocol, status: GRPCStatus) {
        self.delegateQueue.async {
            self.delegate?.speechlyClientDidStopContext(self)
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
        _ sluClient: SluClientProtocol, contextId: String, segmentId: Int, transcript: SluClientDelegate.TentativeTranscript
    ) {
        self.updateContext(contextId, transform: { context in
            let transcripts = transcript.tentativeWords.map { w -> Speechly.Transcript in
                let t = Speechly.Transcript.parseProto(message: w, isFinal: false)

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
        _ sluClient: SluClientProtocol, contextId: String, segmentId: Int, entities: SluClientDelegate.TentativeEntities
    ) {
        self.updateContext(contextId, transform: { context in
            let entities = entities.tentativeEntities.map { e -> Speechly.Entity in
                let entity = Speechly.Entity.parseProto(message: e, isFinal: false)

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
        _ sluClient: SluClientProtocol, contextId: String, segmentId: Int, intent: SluClientDelegate.TentativeIntent
    ) {
        self.updateContext(contextId, transform: { context in
            let intent = Speechly.Intent.parseProto(message: intent, isFinal: false)

            self.delegateQueue.async {
                self.delegate?
                    .speechlyClientDidReceiveIntent(self, contextId: contextId, segmentId: segmentId, intent: intent)
            }

            return try context.addIntent(intent, segmentId: segmentId)
        })
    }

    public func sluClientDidReceiveTranscript(
        _ sluClient: SluClientProtocol, contextId: String, segmentId: Int, transcript: SluClientDelegate.Transcript
    ) {
        self.updateContext(contextId, transform: { context in
            let transcript = Speechly.Transcript.parseProto(message: transcript, isFinal: true)

            self.delegateQueue.async {
                self.delegate?
                    .speechlyClientDidReceiveTranscript(self, contextId: contextId, segmentId: segmentId, transcript: transcript)
            }

            return try context.addTranscripts([transcript], segmentId: segmentId)
        })
    }

    public func sluClientDidReceiveEntity(
        _ sluClient: SluClientProtocol, contextId: String, segmentId: Int, entity: SluClientDelegate.Entity
    ) {
        self.updateContext(contextId, transform: { context in
            let entity = Speechly.Entity.parseProto(message: entity, isFinal: true)

            self.delegateQueue.async {
                self.delegate?
                    .speechlyClientDidReceiveEntity(self, contextId: contextId, segmentId: segmentId, entity: entity)
            }

            return try context.addEntities([entity], segmentId: segmentId)
        })
    }

    public func sluClientDidReceiveIntent(
        _ sluClient: SluClientProtocol, contextId: String, segmentId: Int, intent: SluClientDelegate.Intent
    ) {
        self.updateContext(contextId, transform: { context in
            let intent = Speechly.Intent.parseProto(message: intent, isFinal: true)

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
    private func updateContext(_ id: String, transform: (inout AudioContext) throws -> Segment) {
        guard var context = self.contexts.get(contextId: id) else {
            self.delegateQueue.async {
                self.delegate?
                    .speechlyClientDidCatchError(self, error: .parseError("Received response for unknown context"))
            }

            return
        }

        let segment: Segment
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

extension Client: SpeechlyProtocol {
    
    public weak var delegate: SpeechlyDelegate? {
        get {
            return self.delegateVal
        }

        set(newDelegate) {
            self.delegateQueue.sync(flags: .barrier) {
                self.delegateVal = newDelegate
            }
        }
    }

    public func startContext(appId: String? = nil) {
        self.authenticate()
            .flatMap { self.sluClient.connect(token: $0, config: self.appConfig) }
            .flatMapThrowing { try self.audioRecorder.start() }
            .flatMap { self.sluClient.startContext(appId: appId) }
            .whenFailure { error in
                self.delegateQueue.async {
                    // TODO: this will mix API errors and audio recorder errors together.
                    // We should change the error handling so that we can distinguish between the two.
                    self.delegate?.speechlyClientDidCatchError(self, error: .networkError(error.localizedDescription))
                }
            }
    }

    public func stopContext() {
        self.audioRecorder.stop()
    }

    public func suspend() {
        do {
            try self.audioRecorder.suspend()
        } catch {
            os_log("Error suspending audio recorder: %@", log: speechly, type: .error, String(describing: error))
        }

        do {
            try self.sluClient.suspend().wait()
        } catch {
            os_log("Error suspending API client: %@", log: speechly, type: .error, String(describing: error))
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
