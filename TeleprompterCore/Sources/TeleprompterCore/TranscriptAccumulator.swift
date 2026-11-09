/// Combines confirmed (final) speech with the current volatile result,
/// producing the running text the aligner reads its tail from.
public struct TranscriptAccumulator: Sendable, Equatable {
    private let maxFinalizedWords: Int
    private var finalized: [Substring] = []
    private var volatile = ""

    public init(maxFinalizedWords: Int = 30) {
        self.maxFinalizedWords = maxFinalizedWords
    }

    public var text: String {
        (finalized + volatile.split(whereSeparator: \.isWhitespace)).joined(separator: " ")
    }

    public mutating func apply(_ speech: RecognizedSpeech) {
        guard speech.isFinal else {
            volatile = speech.text
            return
        }
        finalized.append(contentsOf: speech.text.split(whereSeparator: \.isWhitespace))
        finalized = Array(finalized.suffix(maxFinalizedWords))
        volatile = ""
    }

    public mutating func reset() {
        finalized = []
        volatile = ""
    }
}
