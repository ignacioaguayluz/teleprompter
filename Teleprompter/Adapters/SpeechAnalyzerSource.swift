@preconcurrency import AVFoundation
import Speech
import TeleprompterCore

/// On-device speech recognition with `SpeechAnalyzer` + `SpeechTranscriber` (S2).
/// Never uses `SFSpeechRecognizer`; no audio leaves the Mac.
actor SpeechAnalyzerSource: SpeechSource {
    enum AssetState: Sendable, Equatable {
        case unsupported
        case downloading(fraction: Double)
        case ready
    }

    enum Failure: Error {
        case localeUnsupported(String)
        case noCompatibleAudioFormat
    }

    private let locale: Locale
    private let input: AudioInput
    private var analyzer: SpeechAnalyzer?
    private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    private var consumerID: UUID?
    private var resultsTask: Task<Void, Never>?

    init(input: AudioInput, locale: Locale = Locale(identifier: "es-MX")) {
        self.input = input
        self.locale = locale
    }

    /// Makes sure the language model for `locale` is installed, downloading it on first use.
    func prepareAssets(onState: @escaping @Sendable (AssetState) -> Void) async throws {
        let supported = await SpeechTranscriber.supportedLocales
        guard supported.contains(where: { $0.identifier(.bcp47) == locale.identifier(.bcp47) }) else {
            onState(.unsupported)
            throw Failure.localeUnsupported(locale.identifier(.bcp47))
        }

        let transcriber = makeTranscriber()
        if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            let progressTask = Task {
                while !Task.isCancelled {
                    onState(.downloading(fraction: request.progress.fractionCompleted))
                    try? await Task.sleep(for: .milliseconds(250))
                }
            }
            defer { progressTask.cancel() }
            try await request.downloadAndInstall()
        }
        onState(.ready)
    }

    func start() async throws -> AsyncThrowingStream<RecognizedSpeech, any Error> {
        await stop()

        let transcriber = makeTranscriber()
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        guard let format = await SpeechAnalyzer.bestAvailableAudioFormat(
            compatibleWith: [transcriber], considering: input.format
        ) else { throw Failure.noCompatibleAudioFormat }

        let (inputStream, inputContinuation) = AsyncStream<AnalyzerInput>.makeStream()
        let converter = BufferConverter(from: input.format, to: format)
        consumerID = input.addConsumer { buffer, _ in
            if let converted = converter.convert(buffer) {
                inputContinuation.yield(AnalyzerInput(buffer: converted))
            }
        }

        let (output, outputContinuation) = AsyncThrowingStream<RecognizedSpeech, any Error>.makeStream()
        resultsTask = Task {
            do {
                for try await result in transcriber.results {
                    outputContinuation.yield(
                        RecognizedSpeech(text: String(result.text.characters), isFinal: result.isFinal)
                    )
                }
                outputContinuation.finish()
            } catch {
                outputContinuation.finish(throwing: error)
            }
        }

        try await analyzer.prepareToAnalyze(in: format)
        try await analyzer.start(inputSequence: inputStream)
        try input.start()

        self.analyzer = analyzer
        self.inputContinuation = inputContinuation
        return output
    }

    func stop() async {
        if let consumerID { input.removeConsumer(consumerID) }
        consumerID = nil
        inputContinuation?.finish()
        inputContinuation = nil
        try? await analyzer?.finalizeAndFinishThroughEndOfInput()
        analyzer = nil
        resultsTask = nil
    }

    private func makeTranscriber() -> SpeechTranscriber {
        SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [.volatileResults, .fastResults],
            attributeOptions: []
        )
    }
}

/// Converts tap buffers to the analyzer's format. Used only from the audio render thread.
private final class BufferConverter: @unchecked Sendable {
    private let converter: AVAudioConverter?
    private let outputFormat: AVAudioFormat

    init(from inputFormat: AVAudioFormat, to outputFormat: AVAudioFormat) {
        self.outputFormat = outputFormat
        self.converter = inputFormat == outputFormat ? nil : AVAudioConverter(from: inputFormat, to: outputFormat)
    }

    func convert(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let converter else { return buffer.copy() as? AVAudioPCMBuffer }
        let ratio = outputFormat.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount((Double(buffer.frameLength) * ratio).rounded(.up)) + 1
        guard let output = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: capacity) else { return nil }

        var consumed = false
        var error: NSError?
        let status = converter.convert(to: output, error: &error) { _, inputStatus in
            if consumed {
                inputStatus.pointee = .noDataNow
                return nil
            }
            consumed = true
            inputStatus.pointee = .haveData
            return buffer
        }
        return status == .error ? nil : output
    }
}
