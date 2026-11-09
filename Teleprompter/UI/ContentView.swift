import SwiftUI
import UniformTypeIdentifiers

/// Container view: binds the view model to the presentational views and keyboard controls (S8).
struct ContentView: View {
    @Bindable var model: TeleprompterViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScriptView(
                script: model.script,
                cursor: model.cursor,
                currentWord: model.currentWord,
                currentLine: model.currentLine,
                fontSize: model.fontSize,
                onTapWord: model.jump(toWord:)
            )
            Divider()
            ControlsBar(
                isActive: model.isActive,
                statusText: statusText,
                devices: model.devices,
                selectedDeviceUID: $model.selectedDeviceUID,
                isRecordingEnabled: $model.isRecordingEnabled,
                onToggle: model.toggleListening,
                onOpen: { model.isImporting = true },
                onPaste: model.pasteScript
            )
        }
        .frame(minWidth: 420, minHeight: 260)
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled()
        .onKeyPress(.space) { model.toggleListening(); return .handled }
        .onKeyPress(.upArrow) { model.previousLine(); return .handled }
        .onKeyPress(.downArrow) { model.nextLine(); return .handled }
        .onAppear { isFocused = true }
        .background(FloatingWindowConfigurator())
        .fileImporter(
            isPresented: $model.isImporting,
            allowedContentTypes: [.plainText, UTType(filenameExtension: "md") ?? .plainText]
        ) { result in
            if case .success(let url) = result { model.importScript(from: url) }
            isFocused = true
        }
    }

    private var statusText: String {
        switch model.status {
        case .idle:
            if let path = model.lastRecordingPath { return "Paused · last recording: \(path)" }
            return "Paused · press Space to start"
        case .preparing: return "Preparing microphone and speech model…"
        case .downloading(let fraction): return "Downloading Spanish (Mexico) model… \(Int(fraction * 100))%"
        case .listening: return model.isRecordingEnabled ? "Listening · recording WAV" : "Listening"
        case .failed(let message): return "Error: \(message)"
        }
    }
}
