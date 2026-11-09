import Testing
@testable import TeleprompterCore

@Suite struct TranscriptAccumulatorTests {
    @Test func volatileResultReplacesPreviousVolatile() {
        var transcript = TranscriptAccumulator()
        transcript.apply(RecognizedSpeech(text: "hoy va", isFinal: false))
        transcript.apply(RecognizedSpeech(text: "hoy vamos a", isFinal: false))

        #expect(transcript.text == "hoy vamos a")
    }

    @Test func finalResultIsKeptAndVolatileIsAppended() {
        var transcript = TranscriptAccumulator()
        transcript.apply(RecognizedSpeech(text: "hoy vamos", isFinal: false))
        transcript.apply(RecognizedSpeech(text: "hoy vamos a hablar", isFinal: true))
        transcript.apply(RecognizedSpeech(text: "de ciber", isFinal: false))

        #expect(transcript.text == "hoy vamos a hablar de ciber")
    }

    @Test func finalResultClearsVolatile() {
        var transcript = TranscriptAccumulator()
        transcript.apply(RecognizedSpeech(text: "hoy vamos", isFinal: false))
        transcript.apply(RecognizedSpeech(text: "hoy vamos", isFinal: true))

        #expect(transcript.text == "hoy vamos")
    }

    @Test func finalizedTextKeepsOnlyTheLastWords() {
        var transcript = TranscriptAccumulator(maxFinalizedWords: 3)
        transcript.apply(RecognizedSpeech(text: "uno dos", isFinal: true))
        transcript.apply(RecognizedSpeech(text: "tres cuatro", isFinal: true))

        #expect(transcript.text == "dos tres cuatro")
    }

    @Test func resetClearsEverything() {
        var transcript = TranscriptAccumulator()
        transcript.apply(RecognizedSpeech(text: "hoy", isFinal: true))
        transcript.apply(RecognizedSpeech(text: "vamos", isFinal: false))
        transcript.reset()

        #expect(transcript.text == "")
    }
}
