import SwiftUI

struct ProfilesView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var isAddingProfile = false
    @State private var isEditingProfile = false
    @State private var selectedProfileId: String? = nil
    
    var body: some View {
        VStack {
            List(selection: $selectedProfileId) {
                ForEach(viewModel.profiles, id: \.id) { profile in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(profile.name)
                                .font(.headline)
                            Text(profile.modelName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if profile.isDefault {
                            Text("Default")
                                .font(.caption)
                                .padding(4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    .tag(profile.id)
                    .contextMenu {
                        Button("Edit") {
                            selectedProfileId = profile.id
                            isEditingProfile = true
                        }
                        
                        Button("Set as Default") {
                            viewModel.setDefaultProfile(id: profile.id)
                        }
                        .disabled(profile.isDefault)
                        
                        Button("Delete") {
                            viewModel.deleteProfile(id: profile.id)
                        }
                        .disabled(profile.isDefault)
                    }
                }
            }
            
            HStack {
                Button("Add Profile") {
                    isAddingProfile = true
                }
                
                Spacer()
                
                Button("Edit") {
                    isEditingProfile = true
                }
                .disabled(selectedProfileId == nil)
                
                Button("Delete") {
                    if let id = selectedProfileId {
                        viewModel.deleteProfile(id: id)
                    }
                }
                .disabled(selectedProfileId == nil || viewModel.profiles.first(where: { $0.id == selectedProfileId })?.isDefault == true)
            }
            .padding(.top)
        }
        .sheet(isPresented: $isAddingProfile) {
            ProfileEditorView(viewModel: viewModel, mode: .add)
        }
        .sheet(isPresented: $isEditingProfile) {
            if let id = selectedProfileId, let profile = viewModel.profiles.first(where: { $0.id == id }) {
                ProfileEditorView(viewModel: viewModel, mode: .edit(profile: profile))
            }
        }
    }
}

enum ProfileEditorMode {
    case add
    case edit(profile: ModelProfile)
}

struct ProfileEditorView: View {
    @ObservedObject var viewModel: SettingsViewModel
    let mode: ProfileEditorMode
    
    @State private var name: String = ""
    @State private var apiEndpoint: String = ""
    @State private var apiKey: String = ""
    @State private var modelName: String = ""
    @State private var temperature: Double = 0.7
    @State private var maxTokens: Int = 2048
    @State private var topP: Double = 1.0
    @State private var frequencyPenalty: Double = 0.0
    @State private var presencePenalty: Double = 0.0
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("Profile Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("API Endpoint", text: $apiEndpoint)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    SecureField("API Key", text: $apiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Model Name", text: $modelName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section(header: Text("Model Parameters")) {
                    VStack(alignment: .leading) {
                        Text("Temperature: \(temperature, specifier: "%.1f")")
                        Slider(value: $temperature, in: 0...2, step: 0.1)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Max Tokens: \(maxTokens)")
                        Slider(value: $maxTokensDouble, in: 256...4096, step: 256)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Top-p: \(topP, specifier: "%.1f")")
                        Slider(value: $topP, in: 0...1, step: 0.1)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Frequency Penalty: \(frequencyPenalty, specifier: "%.1f")")
                        Slider(value: $frequencyPenalty, in: 0...2, step: 0.1)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Presence Penalty: \(presencePenalty, specifier: "%.1f")")
                        Slider(value: $presencePenalty, in: 0...2, step: 0.1)
                    }
                }
            }
            
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                
                Spacer()
                
                Button("Test Connection") {
                    viewModel.testConnection(endpoint: apiEndpoint, key: apiKey, model: modelName)
                }
                
                Button(mode == .add ? "Add" : "Save") {
                    let parameters = ModelParameters(
                        temperature: temperature,
                        maxTokens: maxTokens,
                        topP: topP,
                        frequencyPenalty: frequencyPenalty,
                        presencePenalty: presencePenalty
                    )
                    
                    switch mode {
                    case .add:
                        viewModel.addProfile(
                            name: name,
                            apiEndpoint: apiEndpoint,
                            apiKey: apiKey,
                            modelName: modelName,
                            parameters: parameters
                        )
                    case .edit(let profile):
                        viewModel.updateProfile(
                            id: profile.id,
                            name: name,
                            apiEndpoint: apiEndpoint,
                            apiKey: apiKey,
                            modelName: modelName,
                            parameters: parameters
                        )
                    }
                    
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(name.isEmpty || apiEndpoint.isEmpty || apiKey.isEmpty || modelName.isEmpty)
            }
            .padding()
        }
        .padding()
        .frame(width: 500, height: 600)
        .onAppear {
            if case .edit(let profile) = mode {
                name = profile.name
                apiEndpoint = profile.apiEndpoint
                apiKey = viewModel.getAPIKey(for: profile.id) ?? ""
                modelName = profile.modelName
                temperature = profile.parameters.temperature
                maxTokens = profile.parameters.maxTokens
                topP = profile.parameters.topP
                frequencyPenalty = profile.parameters.frequencyPenalty
                presencePenalty = profile.parameters.presencePenalty
            }
        }
    }
    
    private var maxTokensDouble: Binding<Double> {
        Binding<Double>(
            get: { Double(maxTokens) },
            set: { maxTokens = Int($0) }
        )
    }
}

// Preview provider for SwiftUI Canvas
struct ProfilesView_Previews: PreviewProvider {
    static var previews: some View {
        ProfilesView(viewModel: SettingsViewModel())
    }
}
