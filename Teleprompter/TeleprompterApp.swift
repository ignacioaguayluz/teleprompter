import SwiftUI

@main
struct TeleprompterApp: App {
    @State private var model = TeleprompterViewModel()

    var body: some Scene {
        Window("Teleprompter", id: "main") {
            ContentView(model: model)
        }
        .defaultSize(width: 760, height: 420)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Script…") { model.isImporting = true }
                    .keyboardShortcut("o")
                Button("Paste Script") { model.pasteScript() }
                    .keyboardShortcut("v", modifiers: [.command, .shift])
            }
            CommandMenu("Prompter") {
                Button(model.isActive ? "Pause" : "Start") { model.toggleListening() }
                Button("Larger Text") { model.increaseFont() }
                    .keyboardShortcut("+")
                Button("Smaller Text") { model.decreaseFont() }
                    .keyboardShortcut("-")
                Button("Reset to Start") { model.reset() }
                    .keyboardShortcut("r")
            }
        }
    }
}
