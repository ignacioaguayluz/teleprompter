import Testing
@testable import TeleprompterCore

/// Real SpeechAnalyzer es-MX output (2026-11-09) for a synthetic voice reading the sentence below.
/// The recognizer misheard "ciberseguridad" as "Aguirre de" and "entre" as "in".
@Suite struct RecordedSpeechTests {
    static let recorded: [RecognizedSpeech] = [
        RecognizedSpeech(text: "Hoy", isFinal: false),
        RecognizedSpeech(text: "Hoy vamos", isFinal: false),
        RecognizedSpeech(text: "Hoy vamos,", isFinal: false),
        RecognizedSpeech(text: "Hoy vamos, habla", isFinal: false),
        RecognizedSpeech(text: "Hoy vamos, habla de", isFinal: false),
        RecognizedSpeech(text: "Hoy vamos, habla de Agu", isFinal: false),
        RecognizedSpeech(text: "Hoy vamos, habla de Aguir", isFinal: false),
        RecognizedSpeech(text: "Hoy vamos, habla de Aguirre de", isFinal: false),
        RecognizedSpeech(text: "Hoy vamos, habla de Aguirre de en", isFinal: false),
        RecognizedSpeech(text: "Hoy vamos, habla de Aguirre de en el", isFinal: false),
        RecognizedSpeech(text: "Hoy vamos, habla de Aguirre de en el conf", isFinal: false),
        RecognizedSpeech(text: "Hoy vamos, habla de Aguirre de en el conflic", isFinal: false),
        RecognizedSpeech(text: "Hoy vamos, habla de Aguirre de en el conflicto in", isFinal: false),
        RecognizedSpeech(text: "Hoy vamos, habla de Aguirre de en el conflicto in dos", isFinal: false),
        RecognizedSpeech(text: "Hoy vamos, habla de Aguirre de en el conflicto in dos países", isFinal: false),
        RecognizedSpeech(text: "Hoy vamos, habla de Aguirre de en el conflicto in dos países ve", isFinal: false),
        RecognizedSpeech(text: "Hoy vamos, habla de Aguirre de en el conflicto in dos países vecin", isFinal: false),
        RecognizedSpeech(text: "Hoy vamos, habla de Aguirre de en el conflicto in dos países veciners", isFinal: false),
        RecognizedSpeech(text: "Hoy vamos, habla de Aguirre de en el conflicto en dos países vecinos.", isFinal: true),
    ]

    @Test func cursorFollowsRealRecognizerOutputWithoutGoingBack() {
        let aligner = ScriptAligner(script: Script(
            markdown: "Hoy vamos a hablar de ciberseguridad en el conflicto entre dos países vecinos."
        ))
        var transcript = TranscriptAccumulator()
        var state = AlignerState()
        var cursors: [Int] = []

        for speech in Self.recorded {
            transcript.apply(speech)
            state = aligner.align(state, recognized: transcript.text)
            cursors.append(state.cursor)
        }

        #expect(cursors == cursors.sorted(), "cursor never moves backward")
        #expect(cursors.last == 12)
    }
}
