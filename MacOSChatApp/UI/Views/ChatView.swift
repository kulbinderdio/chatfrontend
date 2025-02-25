import SwiftUI
import UniformTypeIdentifiers

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var messageText: String = ""
    @State private var isShowingDocumentPicker = false
    
    var body: some View {
        VStack {
            // Messages list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                    }
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding()
            }
            
            // Error message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            // Input area
            HStack {
                // Document drop area
                DocumentDropArea(onDocumentDropped: { url in
                    viewModel.handleDocumentDropped(url: url)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .frame(width: 40, height: 40)
                
                // Document picker button
                Button(action: {
                    isShowingDocumentPicker = true
                }) {
                    Image(systemName: "paperclip")
                        .font(.title2)
                }
                .buttonStyle(BorderlessButtonStyle())
                .fileImporter(
                    isPresented: $isShowingDocumentPicker,
                    allowedContentTypes: [.plainText, .pdf, .rtf, .html],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        if let url = urls.first {
                            viewModel.handleDocumentDropped(url: url)
                        }
                    case .failure(let error):
                        viewModel.errorMessage = error.localizedDescription
                    }
                }
                
                // Text input
                NativeTextField(
                    text: $messageText,
                    placeholder: "Type a message...",
                    onCommit: {
                        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmedText.isEmpty {
                            viewModel.sendMessage(trimmedText)
                            messageText = ""
                        }
                    }
                )
                .frame(height: 40)
                .padding(.horizontal)
                
                // Send button
                Button(action: {
                    let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedText.isEmpty {
                        viewModel.sendMessage(trimmedText)
                        messageText = ""
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(BorderlessButtonStyle())
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .sheet(isPresented: $viewModel.showExtractedTextEditor) {
            if let text = viewModel.extractedDocumentText, let documentName = viewModel.extractedDocumentName {
                ExtractedTextEditorView(
                    viewModel: viewModel,
                    text: Binding(
                        get: { text },
                        set: { viewModel.extractedDocumentText = $0 }
                    ),
                    documentName: documentName
                )
            }
        }
        .alert(isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        let keychainManager = KeychainManager()
        let userDefaultsManager = UserDefaultsManager()
        let modelConfigManager = ModelConfigurationManager(keychainManager: keychainManager, userDefaultsManager: userDefaultsManager)
        
        // Create a mock database manager that doesn't throw
        let databaseManager: DatabaseManager
        do {
            databaseManager = try DatabaseManager()
        } catch {
            fatalError("Failed to initialize DatabaseManager for preview: \(error.localizedDescription)")
        }
        
        let documentHandler = DocumentHandler()
        let profileManager = ProfileManager(databaseManager: databaseManager, keychainManager: keychainManager)
        
        let viewModel = ChatViewModel(
            modelConfigManager: modelConfigManager,
            databaseManager: databaseManager,
            documentHandler: documentHandler,
            profileManager: profileManager
        )
        
        return ChatView(viewModel: viewModel)
    }
}
