import Foundation
import SpeechlyAPI

// MARK: - SpeechEntity definition.

/// A speech entity.
///
/// An entity is a specific object in the phrase that falls into some kind of category,
/// e.g. in a SAL example "*book book a [burger restaurant](restaurant_type) for [tomorrow](date)"
/// "burger restaurant" would be an entity of type `restaurant_type`,
/// and "tomorrow" would be an entity of type `date`.
///
/// An entity has a start and end indices which map to the indices of `SpeechTranscript`s,
/// e.g. in the example "*book book a [burger restaurant](restaurant_type) for [tomorrow](date)" it would be:
///
/// * Entity "burger restaurant" - `startIndex = 2, endIndex = 3`
/// * Entity "tomorrow" - `startIndex = 5, endIndex = 5`
///
/// The start index is inclusive, but the end index is exclusive, i.e. the interval is `[startIndex, endIndex)`.
public struct Entity: Hashable, Identifiable {
    /// A custom ID implementation for `SpeechEntity`.
    /// Since entities have two indices, start and end,
    /// this struct encapsulates the two for indexing and sorting purposes.
    public struct ID: Hashable, Comparable {
        /// The start index.
        public let start: Int

        /// The end index.
        public let end: Int

        public static func < (lhs: ID, rhs: ID) -> Bool {
            return lhs.start < rhs.start
        }

        public static func <= (lhs: ID, rhs: ID) -> Bool {
            return lhs.start <= rhs.start
        }

        public static func >= (lhs: ID, rhs: ID) -> Bool {
            return lhs.start >= rhs.start
        }

        public static func > (lhs: ID, rhs: ID) -> Bool {
            return lhs.start > rhs.start
        }
    }

    /// The identifier of the entity, unique within a `SpeechSegment`.
    /// Consists of the combination of start and end indices.
    public let id: ID

    /// The value of the entity, as detected by the API and defined by SAL.
    ///
    /// Given SAL `*book book a [burger restaurant](restaurant_type)` and an audio `book an italian place`,
    /// The value will be `italian place`.
    public let value: String

    /// The type (or class) of the entity, as detected by the API and defined by SAL.
    ///
    /// Given SAL `*book book a [burger restaurant](restaurant_type)` and an audio `book an italian place`,
    /// The type will be `restaurant_type`.
    public let type: String

    /// Start index of the entity, correlates with an index of some `SpeechTranscript` in a `SpeechSegment`.
    public let startIndex: Int

    /// End index of the entity, correlates with an index of some `SpeechTranscript` in a `SpeechSegment`.
    public let endIndex: Int

    /// The status of the entity.
    /// `true` for finalised entities, `false` otherwise.
    ///
    /// - Important: if the entity is not final, its values may change.
    public let isFinal: Bool

    /// Creates a new entity.
    ///
    /// - Parameters:
    ///     - value: the value of the entity.
    ///     - type: the type of the entity.
    ///     - startIndex: the index of the beginning of the entity in a segment.
    ///     - endIndex: the index of the end of the entity in a segment.
    ///     - isFinal: the status of the entity.
    public init(value: String, type: String, startIndex: Int, endIndex: Int, isFinal: Bool) {
        self.value = value
        self.type = type
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.isFinal = isFinal
        self.id = ID(start: startIndex, end: endIndex)
    }
}

// MARK: - Comparable protocol conformance.

extension Entity: Comparable {
    public static func < (lhs: Entity, rhs: Entity) -> Bool {
        return lhs.id < rhs.id
    }

    public static func <= (lhs: Entity, rhs: Entity) -> Bool {
        return lhs.id <= rhs.id
    }

    public static func >= (lhs: Entity, rhs: Entity) -> Bool {
        return lhs.id >= rhs.id
    }

    public static func > (lhs: Entity, rhs: Entity) -> Bool {
        return lhs.id > rhs.id
    }
}

// MARK: - SluProtoParseable implementation.

extension Entity: SpeechlyProtoParseable {
    typealias EntityProto = Speechly_Slu_V1_SLUEntity

    static func parseProto(message: EntityProto, isFinal: Bool) -> Entity {
        return self.init(
            value: message.value,
            type: message.entity,
            startIndex: Int(message.startPosition),
            endIndex: Int(message.endPosition),
            isFinal: isFinal
        )
    }
}
