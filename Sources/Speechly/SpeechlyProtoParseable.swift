import Foundation
import SwiftProtobuf

/// A protocol for data types that can be parsed from protocol buffers messages.
///
/// Unfortunately there isn't a good way to restrict this protocol to a subset of messages specific to Speechly SLU API,
/// hence it's using a general `SwiftProtobuf.Message` as a type.
protocol SpeechlyProtoParseable {
    /// The message that can be parsed.
    associatedtype Message = SwiftProtobuf.Message

    /// Creates a new instance of `Self` from the `message`.
    ///
    /// - Parameters:
    ///     - message: The protobuf message to parse.
    ///     - isFinal: Whether the message comes from a final API response.
    /// - Returns: An instance of `Self`.
    static func parseProto(message: Message, isFinal: Bool) -> Self
}
