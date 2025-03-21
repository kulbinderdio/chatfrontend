import SwiftUI
import Down

struct MessageBubble: View {
    let message: Message
    @Environment(\.colorScheme) private var colorScheme
    @State private var isCopied: Bool = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) { // Reduced spacing from 8 to 4
            // Avatar for assistant messages
            if message.role != "user" {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 24))
                    .foregroundColor(.purple)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.purple.opacity(0.1))
                    )
            }
            
            VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 4) {
                // Message content
                ZStack(alignment: .topTrailing) {
                    if message.role == "assistant" {
                        // Use MarkdownText for assistant messages
                        MarkdownText(message.content)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 10) // Reduced horizontal padding from 12 to 10
                            .background(bubbleColor)
                            .foregroundColor(textColor)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                            .font(.system(size: UIConstants.messageFontSize))
                            .lineSpacing(UIConstants.messageLineSpacing)
                        
                        // Copy button for assistant messages
                        Button(action: {
                            copyToClipboard(message.content)
                        }) {
                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 12))
                                .padding(6)
                                .background(
                                    Circle()
                                        .fill(isCopied ? Color.green.opacity(0.9) : Color.white.opacity(0.9))
                                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                )
                                .foregroundColor(isCopied ? .white : .black)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .offset(x: 8, y: -8)
                        .help(isCopied ? "Copied!" : "Copy to clipboard")
                        .animation(.easeInOut(duration: 0.2), value: isCopied)
                    } else {
                        // Regular text for user messages
                        Text(message.content)
                            .padding(12)
                            .background(bubbleColor)
                            .foregroundColor(textColor)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                            .font(.system(size: UIConstants.messageFontSize))
                            .lineSpacing(UIConstants.messageLineSpacing)
                    }
                }
                
                // Timestamp
                Text(formattedTime)
                    .font(.system(size: UIConstants.timestampFontSize))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            .frame(maxWidth: 500, alignment: message.role == "user" ? .trailing : .leading)
            
            // Avatar for user messages
            if message.role == "user" {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                    )
            }
        }
        .padding(.horizontal, message.role == "user" ? 16 : 8) // Reduced horizontal padding for assistant messages
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message.role == "user" ? "You said" : "Assistant said")
        .accessibilityValue(message.content)
        .accessibilityHint(message.role == "user" ? "Your message" : "Assistant's response")
        .id("MessageBubble-\(message.id)") // Unique identifier for UI testing
    }
    
    private var bubbleColor: Color {
        if message.role == "user" {
            return colorScheme == .dark ? Color.blue.opacity(0.8) : Color.blue
        } else {
            return colorScheme == .dark ? 
                Color(red: 0.25, green: 0.25, blue: 0.3) : 
                Color(red: 0.95, green: 0.95, blue: 0.97)
        }
    }
    
    private var textColor: Color {
        if message.role == "user" {
            return .white
        } else {
            return colorScheme == .dark ? .white : .black
        }
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: message.timestamp)
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Show visual feedback
        withAnimation {
            isCopied = true
        }
        
        // Reset after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isCopied = false
            }
        }
    }
}

// Markdown rendering component
struct MarkdownText: View {
    let content: String
    
    init(_ content: String) {
        self.content = content
    }
    
    var body: some View {
        if let attributedString = try? Down(markdownString: content).toAttributedString() {
            // Use the attributed string directly
            Text(AttributedString(attributedString))
        } else {
            Text(content)
        }
    }
}

// Preview provider for SwiftUI Canvas
struct MessageBubble_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode preview
            VStack {
                MessageBubble(message: Message(id: "1", role: "user", content: "Hello, how are you?", timestamp: Date()))
                MessageBubble(message: Message(id: "2", role: "assistant", content: "I'm doing well, thank you for asking! Here's some **markdown** with a [link](https://example.com).", timestamp: Date()))
                MessageBubble(message: Message(id: "3", role: "user", content: "Can you show me some code?", timestamp: Date()))
                MessageBubble(message: Message(id: "4", role: "assistant", content: "Sure, here's a code example:\n\n```swift\nfunc hello() {\n    print(\"Hello, world!\")\n}\n```", timestamp: Date()))
            }
            .padding()
            .previewDisplayName("Light Mode")
            
            // Dark mode preview
            VStack {
                MessageBubble(message: Message(id: "1", role: "user", content: "Hello, how are you?", timestamp: Date()))
                MessageBubble(message: Message(id: "2", role: "assistant", content: "I'm doing well, thank you for asking! Here's some **markdown** with a [link](https://example.com).", timestamp: Date()))
            }
            .padding()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
