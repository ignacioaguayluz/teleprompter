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
}
