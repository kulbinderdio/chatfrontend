import SwiftUI

@main
struct MacOSChatApp: App {
    // Managers
    private let keychainManager = KeychainManager()
    private let userDefaultsManager = UserDefaultsManager()
    private var databaseManager: DatabaseManager!
    private let documentHandler = DocumentHandler()
    private let menuBarManager = MenuBarManager()
    
    // View Models
    @StateObject private var modelConfigManager: ModelConfigurationManager
    @StateObject private var chatViewModel: ChatViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    
    init() {
        // Initialize DatabaseManager with try-catch
        do {
            databaseManager = try DatabaseManager()
        } catch {
            fatalError("Failed to initialize DatabaseManager: \(error.localizedDescription)")
        }
        
        // Initialize ModelConfigurationManager first as it's needed by other view models
        let modelConfig = ModelConfigurationManager(keychainManager: keychainManager, userDefaultsManager: userDefaultsManager)
        _modelConfigManager = StateObject(wrappedValue: modelConfig)
        
        // Initialize ChatViewModel
        let chat = ChatViewModel(
            modelConfigManager: modelConfig,
            databaseManager: databaseManager,
            documentHandler: documentHandler
        )
        _chatViewModel = StateObject(wrappedValue: chat)
        
        // Initialize SettingsViewModel
        let settings = SettingsViewModel(
            modelConfigManager: modelConfig,
            keychainManager: keychainManager,
            userDefaultsManager: userDefaultsManager,
            databaseManager: databaseManager
        )
        _settingsViewModel = StateObject(wrappedValue: settings)
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
            SettingsView(viewModel: settingsViewModel)
        }
    }
    
    private func setupMenuBar() {
        let chatView = ChatView(viewModel: chatViewModel)
        menuBarManager.setupMenuBar(with: chatView)
    }
}
