import Foundation
import NIO

// MARK: - SpeechClientProtocol definition.

/// A speech client protocol.
///
/// The purpose of a speech client is to abstract away the handling of audio recording and API streaming,
/// providing the user with a high-level abstraction over the microphone speech recognition.
public protocol SpeechClientProtocol {
    /// A delegate which is called when the client has received and parsed messages from the API.
    /// The delegate will also be called when the client catches an error.
    var delegate: SpeechClientDelegate? { get set }

    /// Start a new recognition context and unmute the microphone.
    ///
    /// - Parameters:
    ///   - appId: Define a specific Speechly appId to send the audio to. Not needed if the appId can be inferred from login.
    ///
    /// - Important: Calling `start` again after another `start` call will stop the previous recognition context.
    ///   Starting a recognition context is an asynchronous operation.
    ///   Use `speechlyClientDidStart` method in `SpeechClientDelegate` protocol for acknowledgments from the client.
    func start(appId: String?)

    /// Stop current recognition context and mute the microphone.
    ///
    /// - Important: Calling `stop` again after another `stop` call is a no-op.
    ///   Stopping a recognition context is an asynchronous operation.
    ///   Use `speechlyClientDidStop` method in `SpeechClientDelegate` protocol for acknowledgments from the client.
    func stop()

    /// Suspend the client, releasing any resources and cleaning up any pending contexts.
    ///
    /// This method should be used when your application is about to enter background state.
    func suspend()

    /// Resume the client, re-initialing necessary resources to continue the operation.
    ///
    /// This method should be used when your application is about to leave background state.
    func resume() throws
}

// MARK: - SpeechClientDelegate definition.

/// Delegate called when a speech client handles messages from the API or catches an error.
///
/// The intended use of this protocol is with `SpeechClientProtocol`.
///
/// - Important: In order to avoid retain cycles, classes implementing this delegate
///   MUST NOT maintain a strong reference to the `SpeechClientProtocol`.
public protocol SpeechClientDelegate: class {
    /// Called when the client catches an error.
    ///
    /// - Parameters:
    ///   - error: The error which was caught.
    func speechlyClientDidCatchError(_ speechlyClient: SpeechClientProtocol, error: SpeechClientError)

    /// Called after the client has acknowledged a recognition context start.
    func speechlyClientDidStart(_ speechlyClient: SpeechClientProtocol)

    /// Called after the client has acknowledged a recognition context stop.
    func speechlyClientDidStop(_ speechlyClient: SpeechClientProtocol)

    /// Called after the client has processed an update to current `SpeechSegment`.
    ///
    /// When the client receives messages from the API, it will use them to update the state of current speech segment,
    /// and dispatch the updated state to the delegate. The delegate can use these updates to react to the user input
    /// by using the intent, entities and transcripts contained in the segment.
    ///
    /// Only one segment is active at a time, but since the processing is asynchronous,
    /// it is possible to have out-of-order delivery of segments.
    ///
    /// - Parameters:
    ///   - segment: The speech segment that has been updated.
    func speechlyClientDidUpdateSegment(_ speechlyClient: SpeechClientProtocol, segment: SpeechSegment)

    /// Called after the client has received a new transcript message from the API.
    ///
    /// - Parameters:
    ///   - contextId: The ID of the recognition context that the transcript belongs to.
    ///   - segmentId: The ID of the speech segment that the transcript belongs to.
    ///   - transcript: The transcript received from the API.
    func speechlyClientDidReceiveTranscript(
        _ speechlyClient: SpeechClientProtocol, contextId: String, segmentId: Int, transcript: SpeechTranscript
    )

    /// Called after the client has received a new entity message from the API.
    ///
    /// - Parameters:
    ///   - contextId: The ID of the recognition context that the entity belongs to.
    ///   - segmentId: The ID of the speech segment that the entity belongs to.
    ///   - entity: The entity received from the API.
    func speechlyClientDidReceiveEntity(
        _ speechlyClient: SpeechClientProtocol, contextId: String, segmentId: Int, entity: SpeechEntity
    )

    /// Called after the client has received a new intent message from the API.
    ///
    /// - Parameters:
    ///   - contextId: The ID of the recognition context that the intent belongs to.
    ///   - segmentId: The ID of the speech segment that the intent belongs to.
    ///   - transcript: The intent received from the API.
    func speechlyClientDidReceiveIntent(
        _ speechlyClient: SpeechClientProtocol, contextId: String, segmentId: Int, intent: SpeechIntent
    )
}

/// Errors caught by `SpeechClientProtocol` and dispatched to `SpeechClientDelegate`.
public enum SpeechClientError: Error {
    /// A network-level error.
    /// Usually these errors are unrecoverable and require a full restart of the client.
    case networkError(String)

    /// An error within the audio recorder stack.
    /// Normally these errors are recoverable and do not require any special handling.
    /// However, these errors will result in downgraded recognition performance.
    case audioError(String)

    /// An error within the API.
    /// Normally these errors are recoverable, but they may result in dropped API responses.
    case apiError(String)

    /// An error within the API message parsing logic.
    /// These errors are fully recoverable, but will result in missed speech segment updates.
    case parseError(String)
}

// MARK: - SpeechClientDelegate default implementation.

public extension SpeechClientDelegate {
    func speechlyClientDidStart(_ speechlyClient: SpeechClientProtocol) {}
    func speechlyClientDidStop(_ speechlyClient: SpeechClientProtocol) {}
    func speechlyClientDidCatchError(_ speechlyClient: SpeechClientProtocol, error: SpeechClientError) {}
    func speechlyClientDidUpdateSegment(_ speechlyClient: SpeechClientProtocol, segment: SpeechSegment) {}
    func speechlyClientDidReceiveTranscript(
        _ speechlyClient: SpeechClientProtocol, contextId: String, segmentId: Int, transcript: SpeechTranscript
    ) {}
    func speechlyClientDidReceiveEntity(
        _ speechlyClient: SpeechClientProtocol, contextId: String, segmentId: Int, entity: SpeechEntity
    ) {}
    func speechlyClientDidReceiveIntent(
        _ speechlyClient: SpeechClientProtocol, contextId: String, segmentId: Int, intent: SpeechIntent
    ) {}
}
