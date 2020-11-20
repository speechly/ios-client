import Foundation

// MARK: - SpeechSegment definition.

/// A segment is a part of a recognition context (or a phrase) which is defined by an intent.
///
/// e.g. a phrase "book a restaurant and send an invitation to John" contains two intents,
/// "book" and "send an invitation". Thus, the phrase will also contain two segments, "book a restaurant" and
/// "send an invitation to John". A segment has to have exactly one intent that defines it, but it's allowed to have
/// any number of entities and transcripts.
///
/// A segment can be final or tentative. Final segments are guaranteed to only contain final intent, entities
/// and transcripts. Tentative segments can have a mix of final and tentative parts.
public struct SpeechSegment: Hashable, Identifiable {
    private var _entities: [SpeechEntity] = []
    private var _transcripts: [SpeechTranscript] = []
    private var _indexedEntities: [SpeechEntity.ID:SpeechEntity] = [:]
    private var _indexedTranscripts: [Int:SpeechTranscript] = [:]

    /// A unique identifier of the segment.
    public let id: String

    /// The identifier of the segment, which is unique when combined with `contextId`.
    public let segmentId: Int

    /// A unique identifier of the `SpeechContext` that the segment belongs to
    public let contextId: String

    /// The status of the segment. `true` when the segment is finalised, `false` otherwise.
    public var isFinal: Bool = false

    /// The intent of the segment. Returns an empty tentative intent by default.
    public var intent: SpeechIntent = SpeechIntent.Empty

    /// The entities belonging to the segment.
    public var entities: [SpeechEntity] {
        get {
            return self._entities
        }

        set(newValue) {
            self._entities = newValue.sorted()

            self._indexedEntities = newValue.reduce(into: [SpeechEntity.ID:SpeechEntity]()) { (acc, entity) in
                acc[entity.id] = entity
            }
        }
    }

    /// The transcripts belonging to the segment.
    public var transcripts: [SpeechTranscript] {
        get {
            return self._transcripts
        }

        set(newValue) {
            self._transcripts = newValue.sorted()

            self._indexedTranscripts = newValue.reduce(into: [Int:SpeechTranscript]()) { (acc, transcript) in
                acc[transcript.index] = transcript
            }
        }
    }

    /// Creates a new tentative segment with empty intent, entities and transcripts.
    ///
    /// - Parameters:
    ///     - segmentId: The identifier of the segment within a `SpeechContext`.
    ///     - contextId: The identifier of the `SpeechContext` that this segment belongs to.
    public init(segmentId: Int, contextId: String) {
        self.segmentId = segmentId
        self.contextId = contextId
        self.id = "\(contextId)-\(segmentId)"
    }

    /// Creates a new segment with provided parameters.
    ///
    /// - Parameters:
    ///     - segmentId: The identifier of the segment within a `SpeechContext`.
    ///     - contextId: The identifier of the `SpeechContext` that this segment belongs to.
    ///     - isFinal: Indicates whether the segment is final or tentative.
    ///     - intent: The intent of the segment.
    ///     - entities: The entities belonging to the segment.
    ///     - transcripts: The transcripts belonging to the segment.
    ///
    /// - Important: this initialiser does not check for consistency. Passing non-final intent, entities or transcripts
    ///   alongside `isFinal: true` will violate the guarantee that a final segment will only contain final parts.
    public init(
        segmentId: Int,
        contextId: String,
        isFinal: Bool,
        intent: SpeechIntent,
        entities: [SpeechEntity],
        transcripts: [SpeechTranscript]
    ) {
        self.init(segmentId: segmentId, contextId: contextId)

        self.isFinal = isFinal
        self.intent = intent
        self.entities = entities
        self.transcripts = transcripts
    }
}

// MARK: - Comparable protocol conformance.

extension SpeechSegment: Comparable {
    public static func < (lhs: SpeechSegment, rhs: SpeechSegment) -> Bool {
        return lhs.id < rhs.id
    }

    public static func <= (lhs: SpeechSegment, rhs: SpeechSegment) -> Bool {
        return lhs.id <= rhs.id
    }

    public static func >= (lhs: SpeechSegment, rhs: SpeechSegment) -> Bool {
        return lhs.id >= rhs.id
    }

    public static func > (lhs: SpeechSegment, rhs: SpeechSegment) -> Bool {
        return lhs.id > rhs.id
    }
}

// MARK: - Parsing logic implementation.

extension SpeechSegment {
    enum SegmentParseError: Error {
        case transcriptFinalised, entityFinalised, intentFinalised
        case emptyTranscript, emptyIntent
        case segmentFinalised
    }

    mutating func setIntent(_ value: SpeechIntent) throws {
        if self.isFinal {
            throw SegmentParseError.segmentFinalised
        }

        if self.intent.isFinal {
            throw SegmentParseError.intentFinalised
        }

        self.intent = value
    }

    mutating func addEntity(_ value: SpeechEntity) throws {
        if self.isFinal {
            throw SegmentParseError.segmentFinalised
        }

        if let e = self._indexedEntities[value.id], e.isFinal {
            throw SegmentParseError.entityFinalised
        }

        self._indexedEntities[value.id] = value
        self._entities = Array(self._indexedEntities.values).sorted()
    }

    mutating func addTranscript(_ value: SpeechTranscript) throws {
        if self.isFinal {
            throw SegmentParseError.segmentFinalised
        }

        if let t = self._indexedTranscripts[value.index], t.isFinal {
            throw SegmentParseError.transcriptFinalised
        }

        self._indexedTranscripts[value.index] = value
        self._transcripts = Array(self._indexedTranscripts.values).sorted()
    }

    mutating func finalise() throws {
        if self.isFinal {
            return
        }

        if !self.intent.isFinal {
            throw SegmentParseError.emptyIntent
        }

        for (k, v) in self._indexedTranscripts {
            if !v.isFinal {
                self._indexedTranscripts.removeValue(forKey: k)
            }
        }

        if self.transcripts.count == 0 {
            throw SegmentParseError.emptyTranscript
        }

        for (k, v) in self._indexedEntities {
            if !v.isFinal {
                self._indexedEntities.removeValue(forKey: k)
            }
        }

        self.isFinal = true
        self._entities = Array(self._indexedEntities.values).sorted()
        self._transcripts = Array(self._indexedTranscripts.values).sorted()
    }
}
