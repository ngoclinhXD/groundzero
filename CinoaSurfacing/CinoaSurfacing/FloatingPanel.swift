import AppKit
import SwiftUI

class FloatingPanel<Content: View>: NSPanel {
    init(view: () -> Content, contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow, .hudWindow],
            backing: .buffered,
            defer: false
        )
        self.level = .floating
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        self.contentView = NSHostingView(rootView: view().ignoresSafeArea())
    }
    override var canBecomeKey: Bool {
        return true
    }
        
    override var canBecomeMain: Bool {
        return true
    }
}
