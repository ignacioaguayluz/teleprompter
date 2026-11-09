/// Tunable thresholds for `ScriptAligner` (see "Design: ScriptAligner").
public struct AlignerConfig: Sendable, Equatable {
    /// Number of trailing recognized words compared against the script.
    public var recognizedTailLength = 6
    /// Script words before the cursor included in the search window.
    public var windowBehind = 3
    /// Script words after the cursor included in the search window.
    public var windowAhead = 40
    /// Maximum normalized Levenshtein distance for a fuzzy word match.
    public var maxFuzzyDistance = 0.34
    /// Minimum word length for fuzzy matching.
    public var minFuzzyLength = 4
    /// Largest forward move treated as a normal advance rather than a jump.
    public var maxAdvance = 10
    /// Consecutive matches needed for a normal advance.
    public var minMatchesToAdvance = 2
    /// Minimum length of a single word allowed to advance by one on its own.
    public var minSingleWordLength = 6
    /// Consecutive matches needed for a forward jump.
    public var minMatchesToJump = 3
    /// Consecutive matches needed to move backward.
    public var minMatchesToMoveBack = 3

    public init() {}
}

/// Tracker state: index of the last confirmed script word (-1 before the first word).
public struct AlignerState: Sendable, Equatable {
    public var cursor: Int

    public init(cursor: Int = -1) {
        self.cursor = cursor
    }
}

/// Locates the reader in the script from the tail of the recognized speech.
public struct ScriptAligner: Sendable {
    private let words: [String]
    private let config: AlignerConfig

    public init(script: Script, config: AlignerConfig = AlignerConfig()) {
        self.words = script.words.map(\.normalized)
        self.config = config
    }

    public func align(_ state: AlignerState, recognized: String) -> AlignerState {
        let tail = recognized
            .split(whereSeparator: \.isWhitespace)
            .map { TextNormalizer.normalize(String($0)) }
            .filter { !$0.isEmpty }
            .suffix(config.recognizedTailLength)
        guard !tail.isEmpty, !words.isEmpty else { return state }

        let cursor = state.cursor
        let lower = max(0, cursor - config.windowBehind)
        let upper = min(words.count - 1, cursor + config.windowAhead)
        guard lower <= upper else { return state }

        var best: (end: Int, run: Int)?
        for end in lower...upper {
            let run = matchRun(endingAt: end, tail: Array(tail))
            guard run > 0, qualifies(end: end, run: run, cursor: cursor) else { continue }
            if let current = best,
               run < current.run || (run == current.run && abs(end - cursor) >= abs(current.end - cursor)) {
                continue
            }
            best = (end, run)
        }
        return best.map { AlignerState(cursor: $0.end) } ?? state
    }

    private func qualifies(end: Int, run: Int, cursor: Int) -> Bool {
        let distance = end - cursor
        if distance < 0 { return run >= config.minMatchesToMoveBack }
        if distance > config.maxAdvance { return run >= config.minMatchesToJump }
        if run >= config.minMatchesToAdvance { return true }
        return distance == 1 && words[end].count >= config.minSingleWordLength
    }

    /// Counts consecutive matches aligning the recognized tail backwards from script index `end`.
    private func matchRun(endingAt end: Int, tail: [String]) -> Int {
        var i = end
        var j = tail.count - 1
        var run = 0
        while i >= 0, j >= 0 {
            if j >= 1, tail[j - 1] + tail[j] == words[i] {
                i -= 1; j -= 2
            } else if i >= 1, words[i - 1] + words[i] == tail[j] {
                i -= 2; j -= 1
            } else if wordsMatch(words[i], tail[j]) {
                i -= 1; j -= 1
            } else {
                break
            }
            run += 1
        }
        return run
    }

    private func wordsMatch(_ a: String, _ b: String) -> Bool {
        if a == b { return true }
        guard a.count >= config.minFuzzyLength, b.count >= config.minFuzzyLength else { return false }
        let distance = Double(levenshtein(Array(a), Array(b))) / Double(max(a.count, b.count))
        return distance <= config.maxFuzzyDistance
    }

    private func levenshtein(_ a: [Character], _ b: [Character]) -> Int {
        var previous = Array(0...b.count)
        for (i, ca) in a.enumerated() {
            var current = [i + 1]
            for (j, cb) in b.enumerated() {
                current.append(min(previous[j + 1] + 1, current[j] + 1, previous[j] + (ca == cb ? 0 : 1)))
            }
            previous = current
        }
        return previous[b.count]
    }
}
