import SwiftUI

/// Presentational: start/pause, microphone, recording toggle and status (S8, S9, S10).
struct ControlsBar: View {
    let isActive: Bool
    let statusText: String
    let devices: [AudioDevice]
    @Binding var selectedDeviceUID: String?
    @Binding var isRecordingEnabled: Bool
    let onToggle: () -> Void
    let onOpen: () -> Void
    let onPaste: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Label(isActive ? "Pause" : "Start", systemImage: isActive ? "pause.fill" : "mic.fill")
                    .frame(minWidth: 70)
            }
            .help("Start or pause listening (Space)")

            MicPicker(devices: devices, selectedUID: $selectedDeviceUID)
                .disabled(isActive)

            Toggle("Record WAV", isOn: $isRecordingEnabled)
                .disabled(isActive)
                .help("Save the microphone audio to ~/Movies/Teleprompter")

            Text(statusText)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button("Paste", systemImage: "doc.on.clipboard", action: onPaste)
                .help("Load the script from the clipboard (⇧⌘V)")
            Button("Open", systemImage: "folder", action: onOpen)
                .help("Open a .md or .txt script (⌘O)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .focusEffectDisabled()
    }
}
