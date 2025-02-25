import SwiftUI

struct MessageBubble: View {
    let message: Message
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            if message.role == "user" {
                Spacer()
            }
            
            VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(bubbleColor)
                    .foregroundColor(textColor)
                    .cornerRadius(10)
                    .accessibilityLabel(message.role == "user" ? "You said" : "Assistant said")
                    .accessibilityValue(message.content)
                
                Text(formattedTime)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Sent at \(formattedTime)")
            }
            
            if message.role != "user" {
                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(message.role == "user" ? "Your message" : "Assistant's response")
        .id("MessageBubble") // Add identifier for UI testing
    }
    
    private var bubbleColor: Color {
        if message.role == "user" {
            return Color.blue
        } else {
            return colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1)
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
}

// Preview provider for SwiftUI Canvas
struct MessageBubble_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MessageBubble(message: Message(id: "1", role: "user", content: "Hello, how are you?", timestamp: Date()))
            MessageBubble(message: Message(id: "2", role: "assistant", content: "I'm doing well, thank you for asking!", timestamp: Date()))
        }
        .padding()
    }
}
