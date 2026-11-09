import SwiftUI

/// Presentational: audio input selector (S9).
struct MicPicker: View {
    let devices: [AudioDevice]
    @Binding var selectedUID: String?

    var body: some View {
        Picker("Microphone", selection: $selectedUID) {
            ForEach(devices) { device in
                Text(device.name).tag(Optional(device.uid))
            }
        }
        .labelsHidden()
        .frame(maxWidth: 200)
        .help("Microphone used for tracking and recording")
    }
}
