import Testing
@testable import TeleprompterCore

@Suite struct ScriptTests {
    @Test func headingsAreMarkedAndInlineMarkdownIsStripped() {
        let script = Script(markdown: "# Título\n\nHola **mundo**.")

        #expect(script.lines.map(\.text) == ["Título", "Hola mundo."])
        #expect(script.lines.map(\.kind) == [.heading, .paragraph])
        #expect(script.words.map(\.normalized) == ["titulo", "hola", "mundo"])
        #expect(script.words.map(\.lineIndex) == [0, 1, 1])
    }

    @Test func blockquotesAndListMarkersAreRemoved() {
        let script = Script(markdown: "- uno\n* dos\n+ tres\n12. cuatro\n> cinco\n### seis")

        #expect(script.lines.map(\.text) == ["uno", "dos", "tres", "cuatro", "cinco", "seis"])
        #expect(script.lines.last?.kind == .heading)
    }

    @Test func linksKeepTextAndDropUrl() {
        let script = Script(markdown: "Ver [la nota](https://example.com/a) hoy")

        #expect(script.lines.map(\.text) == ["Ver la nota hoy"])
        #expect(script.words.map(\.normalized) == ["ver", "la", "nota", "hoy"])
    }

    @Test func codeAndEmphasisMarkersAreRemoved() {
        let script = Script(markdown: "`código` y _énfasis_ o *cursiva*")

        #expect(script.lines.map(\.text) == ["código y énfasis o cursiva"])
    }

    @Test func plainTextIsLoadedAsParagraphs() {
        let script = Script(markdown: "Primera línea.\nSegunda línea.\n\n")

        #expect(script.lines.map(\.text) == ["Primera línea.", "Segunda línea."])
        #expect(script.lines.allSatisfy { $0.kind == .paragraph })
    }

    @Test func punctuationOnlyTokensAttachToPreviousWord() {
        let script = Script(markdown: "Hola — mundo")

        #expect(script.words.map(\.display) == ["Hola —", "mundo"])
        #expect(script.words.map(\.normalized) == ["hola", "mundo"])
    }

    @Test func wordsHaveSequentialIndices() {
        let script = Script(markdown: "Hoy vamos a hablar de ciberseguridad en el conflicto entre dos países vecinos.")

        #expect(script.words.map(\.normalized) == [
            "hoy", "vamos", "a", "hablar", "de", "ciberseguridad", "en",
            "el", "conflicto", "entre", "dos", "paises", "vecinos",
        ])
        #expect(script.words.map(\.index) == Array(0..<13))
    }

    @Test func lineExposesItsWordRange() {
        let script = Script(markdown: "# Uno dos\nTres cuatro cinco")

        #expect(script.lines.map(\.wordRange) == [0..<2, 2..<5])
    }

    @Test func inlineNoteIsShownButNotAlignable() {
        let script = Script(markdown: "Hola [[sonríe]] mundo")

        #expect(script.words.map(\.normalized) == ["hola", "mundo"])
        #expect(script.lines.map(\.text) == ["Hola mundo"])
        #expect(script.lines[0].notes == [Script.Note(beforeWord: 1, text: "sonríe")])
        #expect(script.lines[0].wordRange == 0..<2)
    }

    @Test func noteOnItsOwnLineHasNoWords() {
        let script = Script(markdown: "[[pausa y respira]]\n\nHola")

        #expect(script.lines.count == 2)
        #expect(script.lines[0].wordRange.isEmpty)
        #expect(script.lines[0].notes == [Script.Note(beforeWord: 0, text: "pausa y respira")])
        #expect(script.words.map(\.normalized) == ["hola"])
        #expect(script.lines[1].wordRange == 0..<1)
    }

    @Test func trailingNoteSitsAfterTheLastWord() {
        let script = Script(markdown: "- Hola mundo [[fin]]")

        #expect(script.lines[0].notes == [Script.Note(beforeWord: 2, text: "fin")])
        #expect(script.words.count == 2)
    }

    @Test func unclosedNoteMarkerStaysAsSpokenText() {
        let script = Script(markdown: "Hola [[mundo")

        #expect(script.lines[0].notes.isEmpty)
        #expect(script.words.map(\.normalized).first == "hola")
        #expect(script.words.count == 2)
    }
}
