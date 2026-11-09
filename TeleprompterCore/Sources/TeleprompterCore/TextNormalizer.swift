/// Normalizes words for alignment: lowercase, diacritics folded, punctuation removed.
/// Implemented with the standard library only (no Foundation) to keep the core pure.
public enum TextNormalizer {
    private static let folding: [Character: Character] = [
        "á": "a", "à": "a", "ä": "a", "â": "a", "ã": "a",
        "é": "e", "è": "e", "ë": "e", "ê": "e",
        "í": "i", "ì": "i", "ï": "i", "î": "i",
        "ó": "o", "ò": "o", "ö": "o", "ô": "o", "õ": "o",
        "ú": "u", "ù": "u", "ü": "u", "û": "u",
        "ñ": "n", "ç": "c",
    ]

    /// Returns the normalized form of a single token, or an empty string if it has no letters or digits.
    public static func normalize(_ token: String) -> String {
        var result = ""
        for character in token.lowercased() where character.isLetter || character.isNumber {
            result.append(folding[character] ?? character)
        }
        return result
    }
}
