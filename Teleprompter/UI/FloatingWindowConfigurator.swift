import AppKit
import SwiftUI

/// Makes the hosting window float above other apps, join all Spaces and remember its frame (S7).
struct FloatingWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { WindowHookView() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class WindowHookView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window else { return }
            window.level = .floating
            window.collectionBehavior.formUnion([.canJoinAllSpaces, .fullScreenAuxiliary])
            window.setFrameAutosaveName("TeleprompterMainWindow")
        }
    }
}
