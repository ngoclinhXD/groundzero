import SwiftUI
import HotKey

class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: FloatingPanel<ContentView>?
    var statusItem: NSStatusItem?
    var settingsWindow: NSWindow? // Keep track of settings window
    
    let hotKey = HotKey(key: .space, modifiers: [.option])

    func applicationDidFinishLaunching(_ notification: Notification) {
        // --- 1. SETUP MAIN PANEL ---
        panel = FloatingPanel(
            view: { ContentView() },
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 600)
        )
        panel?.center()
        panel?.orderOut(nil)
        panel?.hidesOnDeactivate = true

        // --- 2. SETUP STATUS BAR ---
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "circle.circle.fill", accessibilityDescription: "Gemini")
            // CRITICAL: We don't set a simple action. We set a custom event handler.
            button.action = #selector(handleStatusBarClick(sender:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // --- 3. HOTKEY ---
        hotKey.keyDownHandler = { [weak self] in
            self?.togglePanel()
        }
    }
    
    // --- CLICK HANDLER ---
    @objc func handleStatusBarClick(sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        
        if event.type == .rightMouseUp || (event.modifierFlags.contains(.control)) {
            // RIGHT CLICK -> Show Menu
            showContextMenu(sender)
        } else {
            // LEFT CLICK -> Toggle App
            togglePanel()
        }
    }
    
    // --- MENU BUILDER ---
    func showContextMenu(_ sender: NSStatusBarButton) {
        let menu = NSMenu()
        
        // Item 1: Settings
        let settingsItem = NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Item 2: Quit
        let quitItem = NSMenuItem(title: "Quit Gemini", action: #selector(quitApp), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        statusItem?.menu = menu // Attach menu temporarily
        statusItem?.button?.performClick(nil) // Trigger it
        statusItem?.menu = nil // Detach it so Left Click still works next time
    }
    
    @objc func openSettings() {
        // YEET INPUT BAR: If the bar is visible, hide it immediately
        panel?.orderOut(nil)
        
        if settingsWindow == nil {
            // (Your existing window creation code goes here...)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 350, height: 300),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Settings"
            window.center()
            window.contentView = NSHostingView(rootView: SettingsView())
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
    
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    @objc func togglePanel() {
        guard let panel = panel else { return }
        
        // YEET SETTINGS: If settings are open, close them immediately
        settingsWindow?.close()
        
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            panel.center()
        }
    }
}

@main
struct CinoaSurfacingApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Settings { EmptyView() }
    }
}
