import SwiftUI
import AppKit

struct ConversationListView: View {
    @ObservedObject var viewModel: ConversationListViewModel
    @State private var searchText: String = ""
    @State private var isEditingTitle: Bool = false
    @State private var editingConversationId: String? = nil
    @State private var newTitle: String = ""
    @State private var showingExportOptions: Bool = false
    @State private var conversationToExport: Conversation? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search conversations", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onChange(of: searchText) { newValue in
                        viewModel.searchQuery = newValue
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        viewModel.searchQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(8)
            .background(Color(.textBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            .padding([.horizontal, .top])
            
            // Conversation list
            List {
                ForEach(viewModel.filteredConversations) { conversation in
                    ConversationRow(
                        conversation: conversation,
                        isSelected: viewModel.currentConversationId == conversation.id,
                        isEditing: editingConversationId == conversation.id,
                        newTitle: $newTitle,
                        onSelect: {
                            viewModel.selectConversation(id: conversation.id)
                        },
                        onDelete: {
                            viewModel.deleteConversation(id: conversation.id)
                        },
                        onStartEditing: {
                            editingConversationId = conversation.id
                            newTitle = conversation.title
                        },
                        onSaveEditing: {
                            viewModel.updateConversationTitle(id: conversation.id, title: newTitle)
                            editingConversationId = nil
                        },
                        onCancelEditing: {
                            editingConversationId = nil
                        },
                        onExport: {
                            conversationToExport = conversation
                            showingExportOptions = true
                        }
                    )
                }
            }
            .listStyle(SidebarListStyle())
            
            // Loading indicator
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .padding(.vertical, 8)
            }
        }
        .popover(isPresented: $showingExportOptions) {
            if let conversation = conversationToExport {
                ExportOptionsView(
                    viewModel: viewModel,
                    conversation: conversation
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

struct ConversationRow: View {
    let conversation: Conversation
    let isSelected: Bool
    let isEditing: Bool
    @Binding var newTitle: String
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onStartEditing: () -> Void
    let onSaveEditing: () -> Void
    let onCancelEditing: () -> Void
    let onExport: () -> Void
    
    var body: some View {
        HStack {
            if isEditing {
                TextField("Conversation title", text: $newTitle, onCommit: onSaveEditing)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(4)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(4)
                
                Button(action: onSaveEditing) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12))
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onCancelEditing) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                VStack(alignment: .leading) {
                    Text(conversation.title)
                        .lineLimit(1)
                    
                    Text(formatDate(conversation.updatedAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    HStack(spacing: 8) {
                        Button(action: onStartEditing) {
                            Image(systemName: "pencil")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: onExport) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .opacity(0.7)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditing {
                onSelect()
            }
        }
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ExportOptionsView: View {
    @ObservedObject var viewModel: ConversationListViewModel
    let conversation: Conversation
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Export Conversation")
                .font(.headline)
            
            Text("Choose a format:")
                .font(.subheadline)
            
            Button("Plain Text (.txt)") {
                exportConversation(format: .plainText)
            }
            .buttonStyle(BorderedButtonStyle())
            .frame(width: 200)
            
            Button("Markdown (.md)") {
                exportConversation(format: .markdown)
            }
            .buttonStyle(BorderedButtonStyle())
            .frame(width: 200)
            
            Button("PDF (.pdf)") {
                exportConversation(format: .pdf)
            }
            .buttonStyle(BorderedButtonStyle())
            .frame(width: 200)
            
            Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top)
        }
        .padding()
        .frame(width: 250, height: 200)
    }
    
    private func exportConversation(format: ExportFormat) {
        viewModel.exportConversation(conversation: conversation, format: format)
        presentationMode.wrappedValue.dismiss()
    }
}
