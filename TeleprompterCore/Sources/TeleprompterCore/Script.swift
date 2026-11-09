/// A script loaded from plain text or Markdown, split into display lines and alignable words.
public struct Script: Sendable, Equatable {
    public enum LineKind: Sendable, Equatable {
        case heading
        case paragraph
    }

    public struct Line: Sendable, Equatable {
        public let text: String
        public let kind: LineKind
        /// Indices into `Script.words` for the words of this line.
        public let wordRange: Range<Int>
    }

    public struct Word: Sendable, Equatable {
        public let index: Int
        /// Text shown on screen, including attached punctuation.
        public let display: String
        /// Normalized form used by the aligner.
        public let normalized: String
        public let lineIndex: Int
    }

    public let lines: [Line]
    public let words: [Word]

    public init(markdown: String) {
        var lines: [Line] = []
        var words: [Word] = []

        for rawLine in markdown.split(separator: "\n", omittingEmptySubsequences: false) {
            guard let (text, kind) = MarkdownStripper.strip(line: String(rawLine)) else { continue }
            let lineIndex = lines.count
            let firstWord = words.count
            var pendingPrefix = ""

            for token in text.split(whereSeparator: \.isWhitespace).map(String.init) {
                let normalized = TextNormalizer.normalize(token)
                if normalized.isEmpty {
                    if words.count > firstWord, let last = words.popLast() {
                        words.append(Word(index: last.index, display: last.display + " " + token,
                                          normalized: last.normalized, lineIndex: lineIndex))
                    } else {
                        pendingPrefix += token + " "
                    }
                    continue
                }
                words.append(Word(index: words.count, display: pendingPrefix + token,
                                  normalized: normalized, lineIndex: lineIndex))
                pendingPrefix = ""
            }

            lines.append(Line(text: text, kind: kind, wordRange: firstWord..<words.count))
        }

        self.lines = lines
        self.words = words
    }
}
