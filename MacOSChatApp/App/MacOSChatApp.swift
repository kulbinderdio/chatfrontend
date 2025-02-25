import SwiftUI

@main
struct MacOSChatApp: App {
    @StateObject private var chatViewModel = ChatViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    
    private let menuBarManager = MenuBarManager()
    
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
