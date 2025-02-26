import SwiftUI

@main
struct MacOSChatApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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
                    
                    // Prevent app from quitting when all windows are closed
                    NSApplication.shared.setActivationPolicy(.accessory)
                    
                    // Create a persistent window to keep the app running
                    let window = NSWindow(
                        contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
                        styleMask: [],
                        backing: .buffered,
                        defer: false
                    )
                    window.isReleasedWhenClosed = false
                    window.orderOut(nil)
                    
                    // Store the window in the app delegate
                    if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                        appDelegate.persistentWindow = window
                    }
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            // Add a custom command group to prevent the app from quitting when all windows are closed
            CommandGroup(replacing: .appInfo) {
                Button("About MacOSChatApp") {
                    // Show about dialog
                    NSApplication.shared.orderFrontStandardAboutPanel(nil)
                }
            }
            
            CommandGroup(replacing: .newItem) {}
            
            CommandGroup(replacing: .windowSize) {}
        }
        
        // Remove the Settings scene and only use the custom window from MenuBarManager
    }
    
    private func setupMenuBar() {
        let chatView = ChatView(
            viewModel: chatViewModel,
            conversationListViewModel: conversationListViewModel
        )
        
        menuBarManager.setupMenuBar(
            with: chatView,
            settingsViewModel: settingsViewModel,
            profileManager: profileManager
        )
    }
}
