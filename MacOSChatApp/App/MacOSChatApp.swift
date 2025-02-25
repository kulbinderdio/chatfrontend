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
    @StateObject private var menuBarManager = MenuBarManager()
    
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
            EmptyView()
                .frame(width: 0, height: 0)
                .onAppear {
                    setupMenuBar()
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        
        Settings {
            SettingsView(
                viewModel: settingsViewModel,
                profileManager: profileManager
            )
        }
    }
    
    private func setupMenuBar() {
        let chatView = ChatView(
            viewModel: chatViewModel,
            conversationListViewModel: conversationListViewModel
        )
        
        menuBarManager.setupMenuBar(with: chatView)
    }
}
