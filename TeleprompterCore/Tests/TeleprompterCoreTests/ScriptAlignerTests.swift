import Testing
@testable import TeleprompterCore

@Suite struct ScriptAlignerTests {
    static let sentence = "Hoy vamos a hablar de ciberseguridad en el conflicto entre dos países vecinos."
    static let longer = sentence + " Mañana vamos a revisar los ataques contra redes eléctricas."

    private func align(_ text: String = sentence, from cursor: Int, heard: String) -> Int {
        let aligner = ScriptAligner(script: Script(markdown: text))
        return aligner.align(AlignerState(cursor: cursor), recognized: heard).cursor
    }

    @Test("Acceptance examples A1–A8", arguments: [
        ("A1", -1, "hoy vamos a hablar", 3),
        ("A2", 3, "de ciber seguridad", 5),
        ("A3", 3, "en el conflicto entre", 9),
        ("A4", 5, "eh bueno como les decía", 5),
        ("A5", 9, "de", 9),
        ("A6", 9, "hablar de ciberseguridad en", 6),
        ("A7", -1, "oi vamos a ablar", 3),
        ("A8", 5, "en el conflicto entre dos países", 11),
    ])
    func acceptance(id: String, cursor: Int, heard: String, expected: Int) {
        #expect(align(from: cursor, heard: heard) == expected, "\(id)")
    }

    @Test func forwardJumpOverTenWordsNeedsThreeMatches() {
        #expect(align(Self.longer, from: 3, heard: "contra redes") == 3)
        #expect(align(Self.longer, from: 3, heard: "ataques contra redes") == 20)
    }

    @Test func singleLongWordAdvancesOnlyToTheNextWord() {
        #expect(align(from: 4, heard: "ciberseguridad") == 5)
        #expect(align(from: 3, heard: "conflicto") == 3)
        #expect(align(from: 7, heard: "conflicto") == 8)
    }

    @Test func singleShortWordDoesNotAdvance() {
        #expect(align(from: 6, heard: "el") == 6)
    }

    @Test func scriptWordSplitAcrossTwoRecognizedWordsAndViceVersa() {
        #expect(align("Hablemos de ciber seguridad hoy", from: 0, heard: "de ciberseguridad") == 3)
    }

    @Test func emptyRecognitionKeepsCursor() {
        #expect(align(from: 4, heard: "  ¿? ") == 4)
    }

    @Test func thresholdsComeFromConfig() {
        var config = AlignerConfig()
        config.minMatchesToAdvance = 5
        let aligner = ScriptAligner(script: Script(markdown: Self.sentence), config: config)
        #expect(aligner.align(AlignerState(cursor: -1), recognized: "hoy vamos a hablar").cursor == -1)
    }
}
