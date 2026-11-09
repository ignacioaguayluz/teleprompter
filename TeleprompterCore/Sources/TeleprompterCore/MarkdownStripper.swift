/// Removes the Markdown syntax supported by S4 from a single line.
enum MarkdownStripper {
    /// Returns the display text and kind of a line, or nil when the line is empty after stripping.
    static func strip(line: String) -> (String, Script.LineKind)? {
        var text = Substring(line).trimmingWhitespace()
        var kind = Script.LineKind.paragraph

        while text.first == ">" {
            text = text.dropFirst().trimmingWhitespace()
        }

        let hashes = text.prefix { $0 == "#" }
        if (1...6).contains(hashes.count), text.dropFirst(hashes.count).first?.isWhitespace == true {
            text = text.dropFirst(hashes.count).trimmingWhitespace()
            kind = .heading
        } else {
            text = removingListMarker(text)
        }

        let inline = stripInline(String(text))
        let collapsed = inline.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        return collapsed.isEmpty ? nil : (collapsed, kind)
    }

    private static func removingListMarker(_ text: Substring) -> Substring {
        if let first = text.first, "-*+".contains(first), text.dropFirst().first?.isWhitespace == true {
            return text.dropFirst(2).trimmingWhitespace()
        }
        let digits = text.prefix { $0.isNumber }
        let rest = text.dropFirst(digits.count)
        if !digits.isEmpty, let marker = rest.first, marker == "." || marker == ")",
           rest.dropFirst().first?.isWhitespace == true {
            return rest.dropFirst(2).trimmingWhitespace()
        }
        return text
    }

    /// Replaces `[text](url)` and `![alt](url)` with their text and drops `*`, `_` and backticks.
    private static func stripInline(_ text: String) -> String {
        var result = ""
        var index = text.startIndex
        while index < text.endIndex {
            let character = text[index]
            if character == "[" || (character == "!" && text[text.index(after: index)...].first == "["),
               let (label, end) = parseLink(in: text, from: character == "!" ? text.index(after: index) : index) {
                result += label
                index = end
                continue
            }
            if !"*_`".contains(character) {
                result.append(character)
            }
            index = text.index(after: index)
        }
        return result
    }

    private static func parseLink(in text: String, from open: String.Index) -> (String, String.Index)? {
        guard let close = text[open...].firstIndex(of: "]") else { return nil }
        let afterClose = text.index(after: close)
        guard afterClose < text.endIndex, text[afterClose] == "(",
              let paren = text[afterClose...].firstIndex(of: ")") else { return nil }
        return (String(text[text.index(after: open)..<close]), text.index(after: paren))
    }
}

extension Substring {
    func trimmingWhitespace() -> Substring {
        guard let start = firstIndex(where: { !$0.isWhitespace }),
              let end = lastIndex(where: { !$0.isWhitespace }) else { return "" }
        return self[start...end]
    }
}
