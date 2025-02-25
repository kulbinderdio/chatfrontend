import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    
    var body: some View {
        VStack {
            Text("Chat Interface")
                .font(.title)
                .padding()
            
            Spacer()
            
            Text("This is a placeholder for the chat interface.")
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack {
                TextField("Type a message...", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {}) {
                    Image(systemName: "paperplane.fill")
                }
                .buttonStyle(BorderedButtonStyle())
            }
            .padding()
        }
        .padding()
    }
}

// Preview provider for SwiftUI Canvas
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(viewModel: ChatViewModel())
    }
}
