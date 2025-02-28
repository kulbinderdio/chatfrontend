import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedObject var profileManager: ProfileManager
    
    @State private var selectedTab = 0
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            HStack {
                Text("Settings")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    // Properly dismiss the window
                    if let window = NSApplication.shared.keyWindow {
                        window.close()
                    } else {
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding()
            
            TabView(selection: $selectedTab) {
                GeneralSettingsView(viewModel: viewModel)
                    .tabItem {
                        Label("General", systemImage: "gear")
                    }
                    .tag(0)
                
                ProfilesView(profileManager: profileManager)
                    .tabItem {
                        Label("Profiles", systemImage: "person.crop.circle")
                    }
                    .tag(1)
                
                AdvancedSettingsView(viewModel: viewModel)
                    .tabItem {
                        Label("Advanced", systemImage: "gearshape.2")
                    }
                    .tag(2)
                
                AboutView()
                    .tabItem {
                        Label("About", systemImage: "info.circle")
                    }
                    .tag(3)
            }
            .padding([.horizontal, .bottom])
        }
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section(header: Text("Appearance")) {
                Toggle("Use System Appearance", isOn: $viewModel.useSystemAppearance)
                
                if !viewModel.useSystemAppearance {
                    Toggle("Dark Mode", isOn: $viewModel.darkModeEnabled)
                        .disabled(viewModel.useSystemAppearance)
                }
                
                Picker("Font Size", selection: $viewModel.fontSize) {
                    Text("Small").tag("small")
                    Text("Medium").tag("medium")
                    Text("Large").tag("large")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Removed model parameters section as it's now handled through profiles
        }
    }
}

struct AdvancedSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var showingClearHistoryAlert = false
    @State private var showingResetSettingsAlert = false
    
    var body: some View {
        Form {
            Section(header: Text("Application")) {
                Toggle("Launch at Login", isOn: $viewModel.launchAtLogin)
                Toggle("Show in Dock", isOn: $viewModel.showInDock)
            }
            
            Section(header: Text("Data Management")) {
                Button("Clear Conversation History") {
                    showingClearHistoryAlert = true
                }
                .foregroundColor(.red)
                
                Button("Reset All Settings") {
                    showingResetSettingsAlert = true
                }
                .foregroundColor(.red)
            }
        }
        .alert(isPresented: $showingClearHistoryAlert) {
            Alert(
                title: Text("Clear Conversation History"),
                message: Text("Are you sure you want to clear all conversation history? This action cannot be undone."),
                primaryButton: .destructive(Text("Clear")) {
                    viewModel.clearConversationHistory()
                },
                secondaryButton: .cancel()
            )
        }
        .alert(isPresented: $showingResetSettingsAlert) {
            Alert(
                title: Text("Reset All Settings"),
                message: Text("Are you sure you want to reset all settings to their default values? This action cannot be undone."),
                primaryButton: .destructive(Text("Reset")) {
                    viewModel.resetAllSettings()
                },
                secondaryButton: .cancel()
            )
        }
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("bionicChat")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Version 1.0.0")
                .font(.headline)
            
            Text("© 2025 Your Company")
                .font(.caption)
            
            Spacer()
            
            HStack {
                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                Spacer()
                Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

struct SettingsView_Previews: PreviewProvider {
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
        
        let profileManager = ProfileManager(databaseManager: databaseManager, keychainManager: keychainManager)
        
        let viewModel = SettingsViewModel(
            modelConfigManager: modelConfigManager,
            keychainManager: keychainManager,
            userDefaultsManager: userDefaultsManager,
            databaseManager: databaseManager,
            profileManager: profileManager
        )
        
        return SettingsView(viewModel: viewModel, profileManager: profileManager)
    }
}
