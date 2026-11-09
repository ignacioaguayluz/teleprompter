import Testing
@testable import TeleprompterCore

@Suite struct ScriptNavigatorTests {
    // line 0: words 0..<2, line 1: words 2..<5, line 2: words 5..<7
    let navigator = ScriptNavigator(script: Script(markdown: "# Uno dos\nTres cuatro cinco\nSeis siete"))

    @Test func currentWordAndLineFollowTheCursor() {
        #expect(navigator.currentWord(cursor: -1) == 0)
        #expect(navigator.currentLine(cursor: -1) == 0)
        #expect(navigator.currentLine(cursor: 1) == 1)
        #expect(navigator.currentWord(cursor: 6) == nil)
        #expect(navigator.currentLine(cursor: 6) == 2)
    }

    @Test func nextLineMovesToTheStartOfTheFollowingLine() {
        #expect(navigator.cursorForNextLine(from: -1) == 1)
        #expect(navigator.cursorForNextLine(from: 3) == 4)
        #expect(navigator.cursorForNextLine(from: 5) == 6)
    }

    @Test func previousLineMovesToTheStartOfThePrecedingLine() {
        #expect(navigator.cursorForPreviousLine(from: 3) == -1)
        #expect(navigator.cursorForPreviousLine(from: 5) == 1)
        #expect(navigator.cursorForPreviousLine(from: -1) == -1)
    }

    @Test func tappingAWordMakesItTheNextWordToRead() {
        #expect(navigator.cursorForTap(onWord: 3) == 2)
        #expect(navigator.cursorForTap(onWord: 0) == -1)
    }
}
