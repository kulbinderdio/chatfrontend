import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            APIConfigView(viewModel: viewModel)
                .tabItem {
                    Label("API", systemImage: "key.fill")
                }
                .tag(0)
            
            ModelSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Model", systemImage: "gear")
                }
                .tag(1)
            
            ProfilesView(viewModel: viewModel)
                .tabItem {
                    Label("Profiles", systemImage: "person.crop.circle")
                }
                .tag(2)
            
            AppearanceView(viewModel: viewModel)
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush.fill")
                }
                .tag(3)
            
            AdvancedView(viewModel: viewModel)
                .tabItem {
                    Label("Advanced", systemImage: "slider.horizontal.3")
                }
                .tag(4)
        }
        .padding()
        .frame(width: 500, height: 400)
    }
}

// API Configuration tab
struct APIConfigView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var apiKey: String = ""
    @State private var apiEndpoint: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("API Configuration")) {
                TextField("API Endpoint", text: $apiEndpoint)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onAppear {
                        apiEndpoint = viewModel.apiEndpoint
                    }
                
                SecureField("API Key", text: $apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onAppear {
                        apiKey = viewModel.apiKey
                    }
                
                Button("Save") {
                    viewModel.updateAPIConfig(endpoint: apiEndpoint, key: apiKey)
                }
                .disabled(apiEndpoint.isEmpty || apiKey.isEmpty)
            }
            
            Section(header: Text("Ollama Integration")) {
                Toggle("Enable Ollama", isOn: $viewModel.ollamaEnabled)
                
                if viewModel.ollamaEnabled {
                    TextField("Ollama Endpoint", text: $viewModel.ollamaEndpoint)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
        }
    }
}

// Model Settings tab
struct ModelSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section(header: Text("Model Selection")) {
                Picker("Model", selection: $viewModel.selectedModel) {
                    ForEach(viewModel.availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(DefaultPickerStyle())
            }
            
            Section(header: Text("Parameters")) {
                VStack(alignment: .leading) {
                    Text("Temperature: \(viewModel.temperature, specifier: "%.1f")")
                    Slider(value: $viewModel.temperature, in: 0...2, step: 0.1)
                }
                
                VStack(alignment: .leading) {
                    Text("Max Tokens: \(viewModel.maxTokens)")
                    Slider(value: $viewModel.maxTokensDouble, in: 256...4096, step: 256)
                }
                
                VStack(alignment: .leading) {
                    Text("Top-p: \(viewModel.topP, specifier: "%.1f")")
                    Slider(value: $viewModel.topP, in: 0...1, step: 0.1)
                }
                
                VStack(alignment: .leading) {
                    Text("Frequency Penalty: \(viewModel.frequencyPenalty, specifier: "%.1f")")
                    Slider(value: $viewModel.frequencyPenalty, in: 0...2, step: 0.1)
                }
                
                VStack(alignment: .leading) {
                    Text("Presence Penalty: \(viewModel.presencePenalty, specifier: "%.1f")")
                    Slider(value: $viewModel.presencePenalty, in: 0...2, step: 0.1)
                }
            }
            
            Button("Reset to Defaults") {
                viewModel.resetToDefaults()
            }
        }
    }
}

// Appearance tab
struct AppearanceView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section(header: Text("Theme")) {
                Toggle("Use System Appearance", isOn: $viewModel.useSystemAppearance)
                
                if !viewModel.useSystemAppearance {
                    Picker("Theme", selection: $viewModel.darkModeEnabled) {
                        Text("Light").tag(false)
                        Text("Dark").tag(true)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            
            Section(header: Text("Font Size")) {
                Picker("Font Size", selection: $viewModel.fontSize) {
                    Text("Small").tag("small")
                    Text("Medium").tag("medium")
                    Text("Large").tag("large")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
    }
}

// Advanced tab
struct AdvancedView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section(header: Text("Application")) {
                Toggle("Launch at Login", isOn: $viewModel.launchAtLogin)
                Toggle("Show in Dock", isOn: $viewModel.showInDock)
            }
            
            Section(header: Text("Data")) {
                Button("Clear Conversation History") {
                    viewModel.clearConversationHistory()
                }
                .foregroundColor(.red)
                
                Button("Reset All Settings") {
                    viewModel.resetAllSettings()
                }
                .foregroundColor(.red)
            }
        }
    }
}

// Preview provider for SwiftUI Canvas
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: SettingsViewModel())
    }
}
