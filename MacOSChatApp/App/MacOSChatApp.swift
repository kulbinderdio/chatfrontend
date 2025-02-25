import SwiftUI

@main
struct MacOSChatApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        
        Settings {
            SettingsView()
        }
    }
}

// Temporary ContentView until we implement the actual ChatView
struct ContentView: View {
    var body: some View {
        Text("MacOS Chat App - Coming Soon")
            .font(.largeTitle)
            .padding()
    }
}
