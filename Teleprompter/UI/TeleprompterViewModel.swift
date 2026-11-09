import AVFoundation
import AppKit
import Observation
import TeleprompterCore

/// Container: orchestrates audio, speech, recording and the aligner for the views (S11).
@MainActor @Observable
final class TeleprompterViewModel {
    enum Status: Equatable {
        case idle
        case preparing
        case downloading(fraction: Double)
        case listening
        case failed(String)
    }

    enum Failure: LocalizedError {
        case microphoneDenied

        var errorDescription: String? {
            "Microphone access is off. Enable it in System Settings → Privacy & Security → Microphone."
        }
    }

    private enum Keys {
        static let fontSize = "fontSize"
        static let deviceUID = "inputDeviceUID"
        static let recording = "recordingEnabled"
        static let lastScript = "lastScriptMarkdown"
    }

    private(set) var script: Script
    private(set) var cursor = -1
    private(set) var status: Status = .idle
    private(set) var devices: [AudioDevice] = []
    private(set) var lastRecordingPath: String?
    var isImporting = false

    var fontSize: Double {
        didSet { defaults.set(fontSize, forKey: Keys.fontSize) }
    }
    var isRecordingEnabled: Bool {
        didSet { defaults.set(isRecordingEnabled, forKey: Keys.recording) }
    }
    var selectedDeviceUID: String? {
        didSet { defaults.set(selectedDeviceUID, forKey: Keys.deviceUID) }
    }

    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private let audio: AudioInput
    @ObservationIgnored private let speech: SpeechAnalyzerSource
    @ObservationIgnored private let recorder: WAVRecorder
    @ObservationIgnored private var aligner: ScriptAligner
    @ObservationIgnored private var navigator: ScriptNavigator
    @ObservationIgnored private var transcript = TranscriptAccumulator()
    @ObservationIgnored private var listenTask: Task<Void, Never>?

    init() {
        let savedScript = UserDefaults.standard.string(forKey: Keys.lastScript)
        let script = Script(markdown: savedScript ?? Self.sampleScript())
        self.script = script
        aligner = ScriptAligner(script: script)
        navigator = ScriptNavigator(script: script)
        audio = AudioInput()
        speech = SpeechAnalyzerSource(input: audio)
        recorder = WAVRecorder(input: audio)
        fontSize = defaults.object(forKey: Keys.fontSize) as? Double ?? 34
        isRecordingEnabled = defaults.bool(forKey: Keys.recording)
        selectedDeviceUID = defaults.string(forKey: Keys.deviceUID)
        refreshDevices()
    }

    var isActive: Bool { listenTask != nil }
    var currentWord: Int? { navigator.currentWord(cursor: cursor) }
    var currentLine: Int? { navigator.currentLine(cursor: cursor) }

    // MARK: Script

    func load(markdown: String) {
        defaults.set(markdown, forKey: Keys.lastScript)
        script = Script(markdown: markdown)
        aligner = ScriptAligner(script: script)
        navigator = ScriptNavigator(script: script)
        moveCursor(to: -1)
    }

    func pasteScript() {
        guard let text = NSPasteboard.general.string(forType: .string), !text.isEmpty else { return }
        load(markdown: text)
    }

    func importScript(from url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            load(markdown: try String(contentsOf: url, encoding: .utf8))
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    // MARK: Manual navigation (S8)

    func nextLine() { moveCursor(to: navigator.cursorForNextLine(from: cursor)) }
    func previousLine() { moveCursor(to: navigator.cursorForPreviousLine(from: cursor)) }
    func jump(toWord index: Int) { moveCursor(to: navigator.cursorForTap(onWord: index)) }
    func reset() { moveCursor(to: -1) }
    func increaseFont() { fontSize = min(fontSize + 4, 120) }
    func decreaseFont() { fontSize = max(fontSize - 4, 14) }

    private func moveCursor(to newCursor: Int) {
        cursor = newCursor
        transcript.reset()
    }

    // MARK: Devices (S9)

    func refreshDevices() {
        devices = AudioDeviceCatalog.inputDevices()
        if selectedDeviceUID.flatMap(AudioDeviceCatalog.device(withUID:)) == nil {
            selectedDeviceUID = AudioDeviceCatalog.defaultInputDevice()?.uid
        }
    }

    // MARK: Listening

    func toggleListening() {
        isActive ? stop() : start()
    }

    func start() {
        guard listenTask == nil else { return }
        status = .preparing
        listenTask = Task { await listen() }
    }

    func stop() {
        listenTask?.cancel()
    }

    private func listen() async {
        do {
            guard await AVCaptureDevice.requestAccess(for: .audio) else { throw Failure.microphoneDenied }
            if let device = selectedDeviceUID.flatMap(AudioDeviceCatalog.device(withUID:)) {
                try audio.select(device)
            }
            try await speech.prepareAssets { [weak self] state in
                Task { @MainActor in self?.apply(state) }
            }
            try Task.checkCancellation()

            let results = try await speech.start()
            if isRecordingEnabled {
                lastRecordingPath = try recorder.startRecording()
            }
            transcript.reset()
            status = .listening

            for try await result in results {
                transcript.apply(result)
                cursor = aligner.align(AlignerState(cursor: cursor), recognized: transcript.text).cursor
            }
            status = .idle
        } catch is CancellationError {
            status = .idle
        } catch {
            status = Task.isCancelled ? .idle : .failed(error.localizedDescription)
        }
        recorder.stopRecording()
        await speech.stop()
        audio.stop()
        listenTask = nil
    }

    private func apply(_ state: SpeechAnalyzerSource.AssetState) {
        if case .downloading(let fraction) = state, status != .listening {
            status = .downloading(fraction: fraction)
        }
    }

    private static func sampleScript() -> String {
        guard let url = Bundle.main.url(forResource: "guion-ejemplo", withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return "# Teleprompter\n\nPaste a script (⇧⌘V) or open a .md / .txt file (⌘O)."
        }
        return text
    }
}
