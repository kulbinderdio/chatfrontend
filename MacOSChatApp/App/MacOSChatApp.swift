import SwiftUI

@main
struct MacOSChatApp: App {
    // Database Manager
    @StateObject private var databaseManager: DatabaseManager
    
    // Managers
    @StateObject private var keychainManager: KeychainManager
    @StateObject private var userDefaultsManager: UserDefaultsManager
    @StateObject private var modelConfigManager: ModelConfigurationManager
    @StateObject private var profileManager: ProfileManager
    
    // Services
    @StateObject private var documentHandler: DocumentHandler
    
    // ViewModels
    @StateObject private var chatViewModel: ChatViewModel
    @StateObject private var conversationListViewModel: ConversationListViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    
    init() {
        // Create instances
        let keychain = KeychainManager()
        let userDefaults = UserDefaultsManager()
        let document = DocumentHandler()
        
        // Initialize database manager
        let dbManager: DatabaseManager
        do {
            dbManager = try DatabaseManager()
        } catch {
            fatalError("Failed to initialize database: \(error.localizedDescription)")
        }
        
        // Initialize model configuration manager
        let configManager = ModelConfigurationManager(
            keychainManager: keychain,
            userDefaultsManager: userDefaults
        )
        
        // Initialize profile manager
        let profManager = ProfileManager(
            databaseManager: dbManager,
            keychainManager: keychain
        )
        
        // Initialize view models
        let chatVM = ChatViewModel(
            modelConfigManager: configManager,
            databaseManager: dbManager,
            documentHandler: document,
            profileManager: profManager
        )
        
        let convListVM = ConversationListViewModel(
            databaseManager: dbManager,
            profileManager: profManager
        )
        
        let settingsVM = SettingsViewModel(
            modelConfigManager: configManager,
            keychainManager: keychain,
            userDefaultsManager: userDefaults,
            databaseManager: dbManager,
            profileManager: profManager
        )
        
        // Assign to StateObjects
        _keychainManager = StateObject(wrappedValue: keychain)
        _userDefaultsManager = StateObject(wrappedValue: userDefaults)
        _databaseManager = StateObject(wrappedValue: dbManager)
        _modelConfigManager = StateObject(wrappedValue: configManager)
        _profileManager = StateObject(wrappedValue: profManager)
        _documentHandler = StateObject(wrappedValue: document)
        _chatViewModel = StateObject(wrappedValue: chatVM)
        _conversationListViewModel = StateObject(wrappedValue: convListVM)
        _settingsViewModel = StateObject(wrappedValue: settingsVM)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                chatViewModel: chatViewModel,
                conversationListViewModel: conversationListViewModel,
                settingsViewModel: settingsViewModel,
                profileManager: profileManager
            )
            .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        
        Settings {
            SettingsView(viewModel: settingsViewModel, profileManager: profileManager)
                .frame(width: 600, height: 400)
        }
        
        // Temporarily comment out MenuBarExtra until MenuBarComponent is implemented
        /*
        MenuBarExtra("MacOSChatApp", systemImage: "bubble.left.and.bubble.right") {
            MenuBarComponent(
                chatViewModel: chatViewModel,
                conversationListViewModel: conversationListViewModel
            )
        }
        */
    }
}

struct ContentView: View {
    @ObservedObject var chatViewModel: ChatViewModel
    @ObservedObject var conversationListViewModel: ConversationListViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var profileManager: ProfileManager
    
    @State private var selectedConversationId: String? = nil
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Sidebar with conversation list
                List(selection: $selectedConversationId) {
                    ForEach(conversationListViewModel.conversations) { conversation in
                        NavigationLink(destination: ChatView(viewModel: chatViewModel)) {
                            VStack(alignment: .leading) {
                                Text(conversation.title)
                                    .font(.headline)
                                
                                if let profileId = conversation.profileId,
                                   let profile = profileManager.profiles.first(where: { $0.id == profileId }) {
                                    Text(profile.name)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(conversation.updatedAt, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .tag(conversation.id)
                    }
                }
                .listStyle(SidebarListStyle())
                .frame(minWidth: 200)
                
                // Toolbar for sidebar
                HStack {
                    Button(action: {
                        conversationListViewModel.createNewConversation()
                    }) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .help("New Conversation")
                    
                    Spacer()
                    
                    Button(action: {
                        if let id = selectedConversationId {
                            conversationListViewModel.deleteConversation(id: id)
                        }
                    }) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .disabled(selectedConversationId == nil)
                    .help("Delete Conversation")
                    
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .help("Settings")
                }
                .padding(.horizontal)
            }
            
            // Main content area
            ChatView(viewModel: chatViewModel)
        }
        .onChange(of: selectedConversationId) { id in
            if let id = id {
                chatViewModel.loadOrCreateConversation(id: id)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(viewModel: settingsViewModel, profileManager: profileManager)
                .frame(width: 600, height: 400)
        }
    }
}
