import SwiftUI
import ScreenCaptureKit // Required for screenshots

struct ContentView: View {
    // --- STATE VARIABLES ---
    @State private var inputText: String = ""
    @State private var responseText: String = ""
    @State private var isThinking: Bool = false
    @State private var animateGradient: Bool = false
    @State private var contentHeight: CGFloat = 0
    @State private var attachedImage: NSImage? = nil // Stores the screenshot
    
    // Focus State for the text box
    @FocusState private var isFocused: Bool
    
    // Connect to your custom API class
    let api = GeminiAPI()

    // --- MAIN UI ---
    var body: some View {
        VStack(spacing: 0) {
            
            // --- INPUT BAR ---
            HStack(spacing: 12) {
                // 1. Animated Thinking Icon
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle().stroke(.white, lineWidth: 2)
                            .scaleEffect(isThinking ? 1.5 : 1.0)
                            .opacity(isThinking ? 0 : 1)
                            .animation(isThinking ? .easeOut(duration: 1).repeatForever(autoreverses: false) : .default, value: isThinking)
                    )
                
                // 2. Text Field
                TextField("Type to Gemini...", text: $inputText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 20, weight: .regular))
                    .focused($isFocused)
                    .onSubmit { runGemini() }
                
                // 3. The "Eye" Button (Screenshot)
                Button(action: takeScreenshot) {
                    if let _ = attachedImage {
                        Image(systemName: "photo.badge.checkmark.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 18))
                    } else {
                        Image(systemName: "eye.fill")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 18))
                    }
                }
                .buttonStyle(.plain)
                .help("Capture Screen Context")
            }
            .padding(18)
            .background(rainbowBackground) // Shared Rainbow
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isThinking ? 0.98 : 1.0)
            .animation(isThinking ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default, value: isThinking)
            .zIndex(2) // Keep on top

            // --- RESPONSE BOX ---
            if !responseText.isEmpty {
                ScrollView {
                    // FIX IS HERE: We use the helper function to render Markdown!
                    Text(toMarkdown(responseText))
                        .font(.system(size: 16, design: .rounded))
                        .lineSpacing(4)
                        .foregroundColor(.white)
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        // Dynamic Height Calculation
                        .background(
                            GeometryReader { geo -> Color in
                                DispatchQueue.main.async {
                                    self.contentHeight = geo.size.height
                                }
                                return Color.clear
                            }
                        )
                }
                // Constrain Height (Min 0, Max 400)
                .frame(height: min(contentHeight, 400))
                .background(rainbowBackground)
                .cornerRadius(20)
                .padding(.top, 10)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 600) // Fixed Window Width
        .preferredColorScheme(.dark)
        .onAppear {
            isFocused = true
            // Start Rainbow Animation
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                animateGradient = true
            }
        }
        // Reset App when clicking away
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            resetApp()
        }
    }
    
    // --- SHARED COMPONENTS ---
    
    var rainbowBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.0, blue: 0.2), // Deep Purple
                Color(red: 0.0, green: 0.1, blue: 0.3), // Deep Blue
                Color(red: 0.2, green: 0.0, blue: 0.1), // Deep Red
                Color(red: 0.1, green: 0.0, blue: 0.2)  // Loop back
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .hueRotation(.degrees(animateGradient ? 360 : 0))
        .opacity(0.9)
        .background(.ultraThinMaterial)
    }
    
    // --- ACTIONS ---
    
    // NEW: Helper function to convert text to Markdown
    func toMarkdown(_ text: String) -> AttributedString {
        do {
            return try AttributedString(markdown: text)
        } catch {
            return AttributedString(text)
        }
    }
    
    func resetApp() {
        inputText = ""
        responseText = ""
        contentHeight = 0
        isThinking = false
        attachedImage = nil
    }

    func takeScreenshot() {
        // 1. Hide Window
        NSApp.hide(nil)
        
        Task {
            // 2. Wait for hide animation (0.2s)
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            do {
                // 3. Capture Screen
                let content = try await SCShareableContent.current
                guard let display = content.displays.first(where: { $0.displayID == CGMainDisplayID() }) else {
                    await MainActor.run { NSApp.unhide(nil) }
                    return
                }
                
                // Using 'exceptingWindows' (The fix from before)
                let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
                
                let config = SCStreamConfiguration()
                config.width = display.width
                config.height = display.height
                config.showsCursor = false
                
                let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
                let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: display.width, height: display.height))
                
                // 4. Restore Window & Save Image
                await MainActor.run {
                    self.attachedImage = nsImage
                    NSApp.unhide(nil)
                    NSApp.activate(ignoringOtherApps: true)
                    self.isFocused = true
                }
            } catch {
                print("Screenshot Error: \(error)")
                await MainActor.run { NSApp.unhide(nil) }
            }
        }
    }
    
    func runGemini() {
        guard !inputText.isEmpty else { return }
        
        let query = inputText
        let imageToSend = attachedImage
        
        // UI Updates: Clear input immediately
        withAnimation {
            inputText = ""
            isThinking = true
            responseText = ""
            contentHeight = 0
            attachedImage = nil
        }
        
        // API Call
        Task {
            do {
                let result = try await api.generateResponse(for: query, image: imageToSend)
                
                DispatchQueue.main.async {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        isThinking = false
                        responseText = result
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    isThinking = false
                    responseText = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}
