/// A script loaded from plain text or Markdown, split into display lines and alignable words.
public struct Script: Sendable, Equatable {
    public enum LineKind: Sendable, Equatable {
        case heading
        case paragraph
    }

    /// A `[[note]]` shown on screen but never spoken or aligned.
    public struct Note: Sendable, Equatable, Hashable {
        /// Index into `Script.words` of the word the note precedes (`wordRange.upperBound` for a trailing note).
        public let beforeWord: Int
        public let text: String

        public init(beforeWord: Int, text: String) {
            self.beforeWord = beforeWord
            self.text = text
        }
    }

    public struct Line: Sendable, Equatable {
        public let text: String
        public let kind: LineKind
        /// Indices into `Script.words` for the words of this line.
        public let wordRange: Range<Int>
        public let notes: [Note]
    }

    /// Stands in for a note while a line is stripped of Markdown and tokenized.
    private static let noteMarker: Character = "\u{E000}"

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
            let (withMarkers, noteTexts) = Self.extractNotes(from: String(rawLine))
            guard let (markedText, kind) = MarkdownStripper.strip(line: withMarkers) else { continue }
            let lineIndex = lines.count
            let firstWord = words.count
            var pendingPrefix = ""
            var notes: [Note] = []
            var pendingNotes = noteTexts[...]

            for token in markedText.split(whereSeparator: \.isWhitespace).map(String.init) {
                if token == String(Self.noteMarker) {
                    if let note = pendingNotes.popFirst() { notes.append(Note(beforeWord: words.count, text: note)) }
                    continue
                }
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

            let text = markedText.split(whereSeparator: { $0.isWhitespace || $0 == Self.noteMarker })
                .joined(separator: " ")
            lines.append(Line(text: text, kind: kind, wordRange: firstWord..<words.count, notes: notes))
        }

        self.lines = lines
        self.words = words
    }

    /// Replaces each closed `[[...]]` with a marker surrounded by spaces and returns the note texts in order.
    private static func extractNotes(from line: String) -> (String, [String]) {
        var result = ""
        var notes: [String] = []
        var rest = line[...]
        while let open = rest.firstRange(of: "[["), let close = rest[open.upperBound...].firstRange(of: "]]") {
            let text = rest[open.upperBound..<close.lowerBound].trimmingWhitespace()
            result += rest[..<open.lowerBound]
            if text.isEmpty {
                result += " "
            } else {
                result += " \(noteMarker) "
                notes.append(String(text))
            }
            rest = rest[close.upperBound...]
        }
        return (result + rest, notes)
    }
}
