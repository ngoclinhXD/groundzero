import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("geminiApiKey") private var apiKey: String = ""
    @AppStorage("geminiModelName") private var modelName: String = "gemini-2.5-flash"
    
    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Gemini Settings")
                .font(.headline)
            
            // --- API KEY ---
            VStack(alignment: .leading) {
                Text("Gemini API Key")
                    .font(.caption)
                    .foregroundColor(.secondary)
                SecureField("Paste AIza... key here", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
            }
            
            // --- MODEL NAME ---
            VStack(alignment: .leading) {
                Text("Model Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("e.g. gemini-2.5-flash", text: $modelName)
                    .textFieldStyle(.roundedBorder)
            }
            
            Divider()
            
            // --- NEW FEATURES ---
            
            // 1. Launch at Login Toggle (FIXED SYNTAX)
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .toggleStyle(.switch)
                .onChange(of: launchAtLogin) { _, newValue in
                    toggleLaunchAtLogin(enabled: newValue)
                }
            
            // 2. Check for Updates Button
            Button(action: {
                if let url = URL(string: "https://github.com/ngoclinhXD/CinoaSurfacing/releases") {
                    NSWorkspace.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Check for Updates")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            
            Divider()
            
            // --- FOOTER ---
            Text("by ngoclin.h with ❤️!")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
                .opacity(0.8)
            
            Button("Close") {
                NSApp.windows.first(where: { $0.title == "Settings" })?.close()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(30)
        .frame(width: 350)
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
    
    func toggleLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
