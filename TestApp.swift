import SwiftUI
import AppKit

@main
struct TestApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set the activation policy to regular to show in dock
        NSApplication.shared.setActivationPolicy(.regular)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Prevent the app from terminating when all windows are closed
        return false
    }
}

struct ContentView: View {
    @State private var showSettings = false
    
    var body: some View {
        VStack {
            Text("Test App")
                .font(.largeTitle)
            
            Button("Open Settings") {
                showSettings = true
            }
            .padding()
        }
        .frame(width: 300, height: 200)
        .sheet(isPresented: $showSettings) {
            SettingsView(isPresented: $showSettings)
        }
    }
}

struct SettingsView: View {
    @Binding var isPresented: Bool
    @State private var text = ""
    
    var body: some View {
        VStack {
            Text("Settings")
                .font(.title)
            
            TextField("Enter text", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Close") {
                isPresented = false
            }
            .padding()
        }
        .frame(width: 400, height: 300)
    }
}
