import Foundation
import SpeechlyAPI

// MARK: - SpeechIntent definition.

/// A speech intent.
///
/// An intent is part of a phrase which defines the action of the phrase,
/// e.g. a phrase "book a restaurant and send an invitation to John" contains two intents,
/// "book" and "send an invitation".
///
/// Intents can and should be used to dispatch the action that the user wants to do in the app
/// (e.g. book a meeting, schedule a flight, reset the form).
public struct Intent: Hashable {
    /// An empty intent. Can be used as default value in other places.
    public static let Empty = Intent(value: "", isFinal: false)

    /// The value of the intent, as defined in Speechly application configuration.
    /// e.g. in the example `*book book a [burger restaurant](restaurant_type)` it would be `book`.
    public let value: String

    /// The status of the intent.
    /// `true` for finalised intents, `false` otherwise.
    ///
    /// - Important: if the intent is not final, its values may change.
    public let isFinal: Bool

    /// Creates a new intent.
    ///
    /// - Parameters:
    ///     - value: the value of the intent.
    ///     - isFinal: the status of the intent.
    public init(value: String, isFinal: Bool) {
        self.value = value
        self.isFinal = isFinal
    }
}

// MARK: - Identifiable protocol conformance.

extension Intent: Identifiable {
    public var id: String {
        return self.value
    }
}

// MARK: - Comparable protocol conformance.

extension Intent: Comparable {
    public static func < (lhs: Intent, rhs: Intent) -> Bool {
        return lhs.value < rhs.value
    }

    public static func <= (lhs: Intent, rhs: Intent) -> Bool {
        return lhs.value <= rhs.value
    }

    public static func >= (lhs: Intent, rhs: Intent) -> Bool {
        return lhs.value >= rhs.value
    }

    public static func > (lhs: Intent, rhs: Intent) -> Bool {
        return lhs.value > rhs.value
    }
}

// MARK: - SluProtoParseable implementation.

extension Intent: SpeechlyProtoParseable {
    typealias IntentProto = Speechly_Slu_V1_SLUIntent

    static func parseProto(message: IntentProto, isFinal: Bool) -> Intent {
        return self.init(value: message.intent, isFinal: isFinal)
    }
}
