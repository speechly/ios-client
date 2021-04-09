import Foundation
import SpeechlyAPI

// MARK: - SpeechTranscript definition.

/// A speech transcript.
///
/// A transcript is a single word in a phrase recognised from the audio.
/// e.g. a phrase "two glasses" will have two transcripts, "two" and "glasses".
public struct Transcript: Hashable {
    /// The index of the transcript in the phrase.
    public let index: Int

    /// The value of the transcript, e.g. "glasses".
    /// The case is not guaranteed, it is up to the consumer to decide whether to change it or not.
    public let value: String

    /// The time offset of the beginning of the transcript in the audio, relative to the beginning of the phrase.
    public let startOffset: TimeInterval

    /// The time offset of the end of the transcript in the audio, relative to the beginning of the phrase.
    public let endOffset: TimeInterval

    /// The status of the transcript.
    /// `true` for finalised intents, `false` otherwise.
    ///
    /// - Important: if the transcript is not final, its value may change.
    public let isFinal: Bool

    /// Creates a new transcript.
    ///
    /// - Parameters:
    ///     - index: the index of the transcript.
    ///     - value: the value of the transcript.
    ///     - startOffset: the time offset of the beginning of the transcript in the phrase.
    ///     - endOffset: the time offset of the end of the transcript in the phrase.
    ///     - isFinal: the status of the transcript.
    public init(index: Int, value: String, startOffset: TimeInterval, endOffset: TimeInterval, isFinal: Bool) {
        self.value = value
        self.index = index
        self.startOffset = startOffset
        self.endOffset = endOffset
        self.isFinal = isFinal
    }
}

// MARK: - Identifiable protocol conformance.

extension Transcript: Identifiable {
    public var id: Int {
        return self.index
    }
}

// MARK: - `Comparable` protocol conformance.

extension Transcript: Comparable {
    public static func < (lhs: Transcript, rhs: Transcript) -> Bool {
        return lhs.index < rhs.index
    }

    public static func <= (lhs: Transcript, rhs: Transcript) -> Bool {
        return lhs.index <= rhs.index
    }

    public static func >= (lhs: Transcript, rhs: Transcript) -> Bool {
        return lhs.index >= rhs.index
    }

    public static func > (lhs: Transcript, rhs: Transcript) -> Bool {
        return lhs.index > rhs.index
    }
}

// MARK: - SluProtoParseable implementation.

extension Transcript: SpeechlyProtoParseable {
    typealias TranscriptProto = Speechly_Slu_V1_SLUTranscript

    static func parseProto(message: TranscriptProto, isFinal: Bool) -> Transcript {
        return self.init(
            index: Int(message.index),
            value: message.word,
            startOffset: Double(message.startTime) / 1000,
            endOffset: Double(message.endTime) / 1000,
            isFinal: isFinal
        )
    }
}
