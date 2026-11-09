import SwiftUI
import TeleprompterCore

@main
struct TeleprompterApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Teleprompter core \(TeleprompterCore.version)")
                .padding()
        }
    }
}
