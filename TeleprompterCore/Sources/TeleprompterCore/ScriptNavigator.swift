/// Manual navigation rules (S8). The "current" word is the next one to read: `cursor + 1`.
public struct ScriptNavigator: Sendable {
    private let script: Script

    public init(script: Script) {
        self.script = script
    }

    /// Index of the next word to read, or nil when the script is finished.
    public func currentWord(cursor: Int) -> Int? {
        let next = cursor + 1
        return script.words.indices.contains(next) ? next : nil
    }

    /// Line holding the next word to read (the last line once finished).
    public func currentLine(cursor: Int) -> Int? {
        if let word = currentWord(cursor: cursor) { return script.words[word].lineIndex }
        return script.lines.indices.last
    }

    public func cursorForNextLine(from cursor: Int) -> Int {
        guard let line = currentLine(cursor: cursor) else { return cursor }
        if line + 1 < script.lines.count {
            return script.lines[line + 1].wordRange.lowerBound - 1
        }
        return script.words.count - 1
    }

    public func cursorForPreviousLine(from cursor: Int) -> Int {
        guard let line = currentLine(cursor: cursor), line > 0 else { return -1 }
        return script.lines[line - 1].wordRange.lowerBound - 1
    }

    public func cursorForTap(onWord index: Int) -> Int {
        index - 1
    }
}
