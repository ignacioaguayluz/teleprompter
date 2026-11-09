/// A piece of recognized speech. Volatile results are provisional and get replaced;
/// final results are confirmed by the recognizer.
public struct RecognizedSpeech: Sendable, Equatable {
    public let text: String
    public let isFinal: Bool

    public init(text: String, isFinal: Bool) {
        self.text = text
        self.isFinal = isFinal
    }
}

/// Port for a speech recognizer that turns live audio into text (S11).
public protocol SpeechSource: Sendable {
    func start() async throws -> AsyncThrowingStream<RecognizedSpeech, any Error>
    func stop() async
}
