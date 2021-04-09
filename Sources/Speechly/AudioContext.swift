import Foundation

// MARK: - SpeechContext definition.

/// The speech recognition context.
///
/// A single context aggregates messages from SLU API, which correspond to the audio portion
/// sent to the API within a single recognition stream.
public struct AudioContext: Hashable, Identifiable {
    private var _segments: [Segment] = []
    private var _indexedSegments: [Int:Segment] = [:]
    private var _segmentsAreDirty: Bool = false

    /// The ID of the segment, assigned by the API.
    public let id: String

    /// The segments belonging to the segment, can be empty if there was nothing recognised from the audio.
    public var segments: [Segment] {
        mutating get {
            if self._segmentsAreDirty {
                self._segments = Array(self._indexedSegments.values).sorted()
                self._segmentsAreDirty = false
            }

            return self._segments
        }

        set(newValue) {
            self._segments = newValue.sorted()
            self._indexedSegments = newValue.reduce(into: [Int:Segment]()) { (acc, segment) in
                acc[segment.segmentId] = segment
            }
        }
    }

    /// Creates a new empty speech context.
    ///
    /// - Parameter id: The identifier of the context.
    public init(id: String) {
        self.id = id
    }

    /// Creates a new speech context.
    ///
    /// - Parameters:
    ///     - id: The identifier of the context.
    ///     - segments: The segments which belong to the context.
    ///
    /// - Important: this initialiser does not check whether `segments` have `id` set as their `contextId` values,
    ///   so it is possible to pass segments to this initialiser that don't belong to this context
    ///   according to the identifiers.
    public init(id: String, segments: [Segment]) {
        self.init(id: id)
        self.segments = segments
    }
}

// MARK: - Comparable protocol conformance.

extension AudioContext: Comparable {
    public static func < (lhs: AudioContext, rhs: AudioContext) -> Bool {
        return lhs.id < rhs.id
    }

    public static func <= (lhs: AudioContext, rhs: AudioContext) -> Bool {
        return lhs.id <= rhs.id
    }

    public static func >= (lhs: AudioContext, rhs: AudioContext) -> Bool {
        return lhs.id >= rhs.id
    }

    public static func > (lhs: AudioContext, rhs: AudioContext) -> Bool {
        return lhs.id > rhs.id
    }
}

// MARK: - Parsing logic implementation.

extension AudioContext {
    mutating func addTranscripts(_ value: [Transcript], segmentId: Int) throws -> Segment {
        return try self.updateSegment(id: segmentId, transform: { segment in
            for t in value {
                try segment.addTranscript(t)
            }
        })
    }

    mutating func addEntities(_ value: [Entity], segmentId: Int) throws -> Segment {
        return try self.updateSegment(id: segmentId, transform: { segment in
            for e in value {
                try segment.addEntity(e)
            }
        })
    }

    mutating func addIntent(_ value: Intent, segmentId: Int) throws -> Segment {
        return try self.updateSegment(id: segmentId, transform: { segment in try segment.setIntent(value) })
    }

    mutating func finaliseSegment(segmentId: Int) throws -> Segment {
        return try self.updateSegment(id: segmentId, transform: { segment in try segment.finalise() })
    }

    mutating func finalise() throws -> AudioContext {
        for (k, v) in self._indexedSegments {
            if !v.isFinal {
                self._indexedSegments.removeValue(forKey: k)
            }
        }

        self._segmentsAreDirty = true

        return self
    }

    private mutating func updateSegment(id: Int, transform: (inout Segment) throws -> Void) rethrows -> Segment {
        var segment = self._indexedSegments[id] ?? Segment(segmentId: id, contextId: self.id)

        try transform(&segment)

        self._indexedSegments[id] = segment
        self._segmentsAreDirty = true

        return segment
    }
}

