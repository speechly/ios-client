import Foundation
import NIO
import GRPC
import SpeechlyAPI

// MARK: - SluClientProtocol definition.

/// A protocol defining a client for Speechly SLU API.
///
/// It exposes functionality for starting and stopping SLU recognition streams
/// and a delegate for receiving the responses.
///
/// - Important: Current approach allows only one recognition stream to be active at any time.
public protocol SluClientProtocol {
    /// A delegate which is called when the client receives messages from the API or catches errors.
    var delegate: SluClientDelegate? { get set }

    /// Connects to the SLU API.
    ///
    /// - Important: Calling `connect` again will first disconnect and then connect again.
    ///
    /// - Parameters:
    ///   - token: An auth token received from Speechly Identity API.
    ///   - config: The configuration of the SLU stream.
    /// - Returns: A future which will be fullfilled when the stream has been connected.
    func connect(token: ApiAccessToken, config: SluConfig) -> EventLoopFuture<Void>
    
    /// Disconnects the current connection to the SLU API.
    ///
    /// If there is an active `Context`, it is cancelled.
    ///
    /// - Returns: A future which is fulfilled when the stream has been disconnected.
    func disconnect() -> EventLoopFuture<Void>

    /// Starts a new SLU recognition stream.
    ///
    /// - Important: Calling `startContext` again will stop previous context and start a new one.
    ///
    /// - Parameters:
    ///   - appId: The target appId for the audio, if not set in the token.
    /// - Returns: A future which will be fullfilled when the stream has been started.
    func startContext(appId: String?) -> EventLoopFuture<Void>
    
    /// Stops the current SLU recognition stream
    ///
    /// - Returns: A future which will be fullfilled when the stream has been closed from the client side.
    func stopContext() -> EventLoopFuture<Void>

    /// Suspends the client by terminating any in-flight streams and disconnecting the channels.
    ///
    /// - Returns: A future which will be fullfilled when the streams and channels are cleaned up.
    func suspend() -> EventLoopFuture<Void>

    /// Resumes the client by restoring the channels and cleaning up any stale streams.
    ///
    /// - Returns: A future which will be fullfilled when the channels are restored.
    func resume() -> EventLoopFuture<Void>

    /// Writes audio data on the current stream.
    ///
    /// - Important: If there is currently no stream, this will return a future that succeeds with `false`,
    ///              indicating that a write has been lost.
    ///
    /// - Parameters:
    ///   - data: The audio data to write to the stream
    /// - Returns: A future which will be fullfilled when the data has been sent.
    func write(data: Data) -> EventLoopFuture<Void>
}

/// SLU stream configuration describes the audio data sent to the stream.
/// If misconfigured, the recognition stream will not produce any useful results.
public struct SluConfig {
    /// The sample rate of the audio sent to the stream, in Hertz.
    public let sampleRate: Double

    /// The number of channels in the audio sent to the stream.
    public let channels: UInt32
}

// MARK: - SluClientDelegate definition.

/// Delegate called when an SLU client receives messages from the API or catches an error.
//
/// The intended use of this protocol is with `SluClientProtocol`.
///
/// - Important: In order to avoid retain cycles, classes implementing this delegate
///   MUST NOT maintain a strong reference to the `SluClientProtocol`.
public protocol SluClientDelegate: AnyObject {
    /// An alias for tentative transcript message.
    typealias TentativeTranscript = Speechly_Slu_V1_SLUTentativeTranscript

    /// An alias for tentative entities message.
    typealias TentativeEntities = Speechly_Slu_V1_SLUTentativeEntities

    /// An alias for tentative intent message.
    typealias TentativeIntent = Speechly_Slu_V1_SLUIntent

    /// An alias for final transcript message.
    typealias Transcript = Speechly_Slu_V1_SLUTranscript

    /// An alias for final entity message.
    typealias Entity = Speechly_Slu_V1_SLUEntity

    /// An alias for final intent message.
    typealias Intent = Speechly_Slu_V1_SLUIntent

    /// Called when the client catches an error.
    ///
    /// - Parameters:
    ///   - error: The error which was caught.
    func sluClientDidCatchError(_ sluClient: SluClientProtocol, error: Error)

    /// Called when a recognition stream is stopped from the server side.
    ///
    /// - Parameters:
    ///   - status: The status that the stream was closed with.
    func sluClientDidStopStream(_ sluClient: SluClientProtocol, status: GRPCStatus)

    /// Called when a recognition stream receives an audio context start message.
    ///
    /// - Parameters:
    ///   - contextId: The ID of the context that was started by the server.
    func sluClientDidReceiveContextStart(_ sluClient: SluClientProtocol, contextId: String)

    /// Called when a recognition stream receives an audio context stop message.
    ///
    /// - Parameters:
    ///   - contextId: The ID of the context that was stopped by the server.
    func sluClientDidReceiveContextStop(_ sluClient: SluClientProtocol, contextId: String)

    /// Called when a recognition stream receives an segment end message.
    ///
    /// - Parameters:
    ///   - contextId: The ID of the context that the segment belongs to.
    ///   - segmentId: The ID of the segment which has ended.
    func sluClientDidReceiveSegmentEnd(
        _ sluClient: SluClientProtocol, contextId: String, segmentId: Int
    )

    /// Called when a recognition stream receives a tentative transcript message.
    ///
    /// - Parameters:
    ///   - contextId: The ID of the context that the segment belongs to.
    ///   - segmentId: The ID of the segment which the transcript belongs to.
    ///   - transcript: The tentative transcript message.
    func sluClientDidReceiveTentativeTranscript(
        _ sluClient: SluClientProtocol, contextId: String, segmentId: Int, transcript: TentativeTranscript
    )

    /// Called when a recognition stream receives a tentative entities message.
    ///
    /// - Parameters:
    ///   - contextId: The ID of the context that the segment belongs to.
    ///   - segmentId: The ID of the segment which the entities belongs to.
    ///   - entities: The tentative entities message.
    func sluClientDidReceiveTentativeEntities(
        _ sluClient: SluClientProtocol, contextId: String, segmentId: Int, entities: TentativeEntities
    )

    /// Called when a recognition stream receives a tentative intent message.
    ///
    /// - Parameters:
    ///   - contextId: The ID of the context that the segment belongs to.
    ///   - segmentId: The ID of the segment which the intent belongs to.
    ///   - intent: The tentative intent message.
    func sluClientDidReceiveTentativeIntent(
        _ sluClient: SluClientProtocol, contextId: String, segmentId: Int, intent: TentativeIntent
    )

    /// Called when a recognition stream receives a final transcript message.
    ///
    /// - Parameters:
    ///   - contextId: The ID of the context that the segment belongs to.
    ///   - segmentId: The ID of the segment which the transcript belongs to.
    ///   - transcript: The transcript message.
    func sluClientDidReceiveTranscript(
        _ sluClient: SluClientProtocol, contextId: String, segmentId: Int, transcript: Transcript
    )

    /// Called when a recognition stream receives a final entity message.
    ///
    /// - Parameters:
    ///   - contextId: The ID of the context that the segment belongs to.
    ///   - segmentId: The ID of the segment which the entity belongs to.
    ///   - entity: The entity message.
    func sluClientDidReceiveEntity(
        _ sluClient: SluClientProtocol, contextId: String, segmentId: Int, entity: Entity
    )

    /// Called when a recognition stream receives a final intent message.
    ///
    /// - Parameters:
    ///   - contextId: The ID of the context that the segment belongs to.
    ///   - segmentId: The ID of the segment which the intent belongs to.
    ///   - intent: The intent message.
    func sluClientDidReceiveIntent(
        _ sluClient: SluClientProtocol, contextId: String, segmentId: Int, intent: Intent
    )
}

// MARK: - SluClientDelegate default implementation.

public extension SluClientDelegate {
    func sluClientDidCatchError(_ sluClient: SluClientProtocol, error: Error){}
    func sluClientDidStopStream(_ sluClient: SluClientProtocol, status: GRPCStatus){}
    func sluClientDidReceiveContextStart(_ sluClient: SluClientProtocol, contextId: String){}
    func sluClientDidReceiveContextStop(_ sluClient: SluClientProtocol, contextId: String){}
    func sluClientDidReceiveSegmentEnd(
        _ sluClient: SluClientProtocol, contextId: String, segmentId: Int
    ){}
    func sluClientDidReceiveTentativeTranscript(
        _ sluClient: SluClientProtocol, contextId: String, segmentId: Int, transcript: TentativeTranscript
    ){}
    func sluClientDidReceiveTentativeEntities(
        _ sluClient: SluClientProtocol, contextId: String, segmentId: Int, entities: TentativeEntities
    ){}
    func sluClientDidReceiveTentativeIntent(
        _ sluClient: SluClientProtocol, contextId: String, segmentId: Int, intent: TentativeIntent
    ){}
    func sluClientDidReceiveTranscript(
        _ sluClient: SluClientProtocol, contextId: String, segmentId: Int, transcript: Speechly.Transcript
    ){}
    func sluClientDidReceiveEntity(
        _ sluClient: SluClientProtocol, contextId: String, segmentId: Int, entity: Speechly.Entity
    ){}
    func sluClientDidReceiveIntent(
        _ sluClient: SluClientProtocol, contextId: String, segmentId: Int, intent: Speechly.Intent
    ){}
}
