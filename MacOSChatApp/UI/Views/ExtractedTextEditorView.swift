import SwiftUI

struct ExtractedTextEditorView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var text: String
    let documentName: String
    @State private var isEditing: Bool = false
    
    // Approximate token limit for most models
    private let tokenLimit = 4096
    
    private var tokenCount: Int {
        viewModel.documentHandler.estimateTokenCount(for: text)
    }
    
    private var isOverTokenLimit: Bool {
        tokenCount > tokenLimit
    }
    
    private var tokenLimitPercentage: Double {
        min(Double(tokenCount) / Double(tokenLimit), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Extracted from: \(documentName)")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    viewModel.cancelExtractedText()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Cancel and close")
            }
            
            HStack {
                Text("You can edit the text before sending:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Approx. \(tokenCount) tokens")
                    .font(.caption)
                    .foregroundColor(isOverTokenLimit ? .red : .secondary)
                    .help("Estimated token count")
            }
            
            // Token usage progress bar
            ProgressView(value: tokenLimitPercentage)
                .progressViewStyle(LinearProgressViewStyle())
                .accentColor(tokenLimitPercentage > 0.9 ? .red : (tokenLimitPercentage > 0.7 ? .orange : .blue))
            
            if isOverTokenLimit {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text("This text exceeds the typical token limit (\(tokenLimit)). Consider trimming it down.")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    Button("Truncate") {
                        truncateText()
                    }
                    .font(.caption)
                    .help("Automatically truncate text to fit within token limit")
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            TextEditor(text: $text)
                .font(.body)
                .padding(8)
                .background(Color(.textBackgroundColor))
                .cornerRadius(8)
                .frame(minHeight: 200)
                .onChange(of: text) { _ in
                    isEditing = true
                }
                .accessibilityLabel("Document text editor")
            
            HStack {
                Spacer()
                
                Button("Cancel") {
                    viewModel.cancelExtractedText()
                }
                .keyboardShortcut(.escape, modifiers: [])
                .help("Cancel and discard changes")
                
                Button("Send") {
                    viewModel.useExtractedText()
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .buttonStyle(BorderedButtonStyle())
                .help("Send text to chat")
                .disabled(text.isEmpty)
            }
        }
        .padding()
        .frame(width: 700, height: 500)
        .onAppear {
            // Reset editing state when view appears
            isEditing = false
        }
    }
    
    private func truncateText() {
        // Truncate text to approximately fit within token limit
        // This is a simple approach - in a real app, you might want to be smarter about where to cut
        let maxChars = tokenLimit * 4 // Rough estimation: 1 token ≈ 4 characters
        
        if text.count > maxChars {
            let index = text.index(text.startIndex, offsetBy: maxChars)
            text = String(text[..<index])
            
            // Add a note about truncation
            text += "\n\n[Text has been truncated due to token limit]"
            
            // Mark as edited
            isEditing = true
        }
    }
}
