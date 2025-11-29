import Foundation
import SwiftUI

class GeminiAPI {
    
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "geminiApiKey") ?? ""
    }
    
    private var modelName: String {
        UserDefaults.standard.string(forKey: "geminiModelName") ?? "gemini-2.5-flash"
    }
    
    // UPDATED: Now accepts an optional image
    func generateResponse(for prompt: String, image: NSImage? = nil) async throws -> String {
        guard !apiKey.isEmpty else { return "Please set your API Key in Settings." }
        
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else { return "Error: Bad URL" }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // --- BUILD THE JSON PAYLOAD ---
        var parts: [[String: Any]] = [
            ["text": prompt]
        ]
        
        // If there is an image, convert to Base64 and add it
        if let img = image, let base64String = img.base64String() {
            let imagePart: [String: Any] = [
                "inline_data": [
                    "mime_type": "image/jpeg",
                    "data": base64String
                ]
            ]
            // Add image BEFORE text (Gemini prefers image first usually, or mixed)
            parts.insert(imagePart, at: 0)
        }
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": parts
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let content = candidates.first?["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let text = parts.first?["text"] as? String {
            return text
        }
        
        return "Error: Could not parse response."
    }
}

// Helper Extension: Convert NSImage to Base64 String
extension NSImage {
    func base64String() -> String? {
        guard let tiffRepresentation = self.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation),
              let jpegData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.5]) // Compress to 0.5 to keep it fast
        else { return nil }
        return jpegData.base64EncodedString()
    }
}
