import SwiftUI

struct ProfilesView: View {
    @ObservedObject var profileManager: ProfileManager
    @State private var isAddingProfile = false
    @State private var isEditingProfile = false
    @State private var selectedProfileId: String? = nil
    @State private var isImportingProfiles = false
    @State private var isExportingProfiles = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        VStack {
            List(selection: $selectedProfileId) {
                ForEach(profileManager.profiles, id: \.id) { profile in
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
                        
                        if profile.id == profileManager.selectedProfileId {
                            Text("Selected")
                                .font(.caption)
                                .padding(4)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    .tag(profile.id)
                    .contextMenu {
                        Button("Edit") {
                            selectedProfileId = profile.id
                            isEditingProfile = true
                        }
                        
                        Button("Duplicate") {
                            duplicateProfile(id: profile.id)
                        }
                        
                        Button("Set as Default") {
                            setDefaultProfile(id: profile.id)
                        }
                        .disabled(profile.isDefault)
                        
                        Button("Select") {
                            profileManager.selectProfile(id: profile.id)
                        }
                        .disabled(profile.id == profileManager.selectedProfileId)
                        
                        Divider()
                        
                        Button("Delete") {
                            deleteProfile(id: profile.id)
                        }
                        .disabled(profile.isDefault || profileManager.profiles.count <= 1 || profile.id == profileManager.selectedProfileId)
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200)
            
            HStack {
                Button("Add Profile") {
                    isAddingProfile = true
                }
                
                Spacer()
                
                Button("Import") {
                    isImportingProfiles = true
                }
                
                Button("Export") {
                    exportProfiles()
                }
                
                Divider()
                
                Button("Select") {
                    if let id = selectedProfileId {
                        profileManager.selectProfile(id: id)
                    }
                }
                .disabled(selectedProfileId == nil || selectedProfileId == profileManager.selectedProfileId)
                
                Button("Set as Default") {
                    if let id = selectedProfileId {
                        setDefaultProfile(id: id)
                    }
                }
                .disabled(selectedProfileId == nil || profileManager.profiles.first(where: { $0.id == selectedProfileId })?.isDefault == true)
                
                Button("Delete") {
                    if let id = selectedProfileId {
                        deleteProfile(id: id)
                    }
                }
                .disabled(selectedProfileId == nil || profileManager.profiles.count <= 1 || selectedProfileId == profileManager.selectedProfileId || profileManager.profiles.first(where: { $0.id == selectedProfileId })?.isDefault == true)
            }
            .padding(.top)
        }
        .sheet(isPresented: $isAddingProfile) {
            ProfileEditorView(profileManager: profileManager, mode: .add)
        }
        .sheet(isPresented: $isEditingProfile) {
            if let id = selectedProfileId, let profile = profileManager.profiles.first(where: { $0.id == id }) {
                ProfileEditorView(profileManager: profileManager, mode: .edit(profile: profile))
            }
        }
        .fileImporter(
            isPresented: $isImportingProfiles,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    profileManager.importProfiles(from: url)
                }
            case .failure(let error):
                showAlert(title: "Import Failed", message: error.localizedDescription)
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onChange(of: profileManager.errorMessage) { newValue in
            if let errorMessage = newValue {
                showAlert(title: "Error", message: errorMessage)
                profileManager.errorMessage = nil
            }
        }
    }
    
    private func setDefaultProfile(id: String) {
        do {
            try profileManager.setDefaultProfile(id: id)
        } catch {
            showAlert(title: "Error", message: "Failed to set default profile: \(error.localizedDescription)")
        }
    }
    
    private func deleteProfile(id: String) {
        do {
            try profileManager.deleteProfile(id: id)
        } catch ProfileError.cannotDeleteLastProfile {
            showAlert(title: "Cannot Delete", message: "You cannot delete the last profile.")
        } catch ProfileError.cannotDeleteSelectedProfile {
            showAlert(title: "Cannot Delete", message: "You cannot delete the currently selected profile.")
        } catch {
            showAlert(title: "Error", message: "Failed to delete profile: \(error.localizedDescription)")
        }
    }
    
    private func duplicateProfile(id: String) {
        do {
            _ = try profileManager.duplicateProfile(id: id)
        } catch {
            showAlert(title: "Error", message: "Failed to duplicate profile: \(error.localizedDescription)")
        }
    }
    
    private func exportProfiles() {
        if let fileURL = profileManager.exportProfiles() {
            isExportingProfiles = true
            
            // Use NSSavePanel to let user choose where to save the file
            let savePanel = NSSavePanel()
            savePanel.nameFieldStringValue = "MacOSChatApp_Profiles.json"
            savePanel.allowedContentTypes = [.json]
            
            savePanel.begin { response in
                if response == .OK, let targetURL = savePanel.url {
                    do {
                        let data = try Data(contentsOf: fileURL)
                        try data.write(to: targetURL)
                    } catch {
                        showAlert(title: "Export Failed", message: error.localizedDescription)
                    }
                }
                isExportingProfiles = false
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

enum ProfileEditorMode {
    case add
    case edit(profile: ModelProfile)
}

struct ProfileEditorView: View {
    @ObservedObject var profileManager: ProfileManager
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
    @State private var isDefault: Bool = false
    
    @State private var isTestingConnection: Bool = false
    @State private var connectionTestResult: String? = nil
    @State private var connectionTestSuccess: Bool = false
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Profile Information")) {
                    NativeTextField(
                        text: $name,
                        placeholder: "Profile Name"
                    )
                    .frame(height: 40)
                    
                    NativeTextField(
                        text: $apiEndpoint,
                        placeholder: "API Endpoint"
                    )
                    .frame(height: 40)
                    
                    NativeTextField(
                        text: $apiKey,
                        placeholder: "API Key",
                        isSecure: true
                    )
                    .frame(height: 40)
                    
                    NativeTextField(
                        text: $modelName,
                        placeholder: "Model Name"
                    )
                    .frame(height: 40)
                    
                    Toggle("Set as Default Profile", isOn: $isDefault)
                }
                
                Section(header: Text("Model Parameters")) {
                    VStack(alignment: .leading) {
                        Text("Temperature: \(temperature, specifier: "%.1f")")
                        Slider(value: $temperature, in: 0...2, step: 0.1)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Max Tokens: \(maxTokens)")
                        Slider(value: Binding<Double>(
                            get: { Double(maxTokens) },
                            set: { maxTokens = Int($0) }
                        ), in: 256...4096, step: 256)
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
                
                if let result = connectionTestResult {
                    Section(header: Text("Connection Test")) {
                        HStack {
                            Image(systemName: connectionTestSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(connectionTestSuccess ? .green : .red)
                            Text(result)
                        }
                    }
                }
            }
            
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                
                Spacer()
                
                Button("Test Connection") {
                    testConnection()
                }
                .disabled(apiEndpoint.isEmpty || apiKey.isEmpty || modelName.isEmpty || isTestingConnection)
                
                Button(action: {
                    saveProfile()
                }) {
                    Text(modeIsAdd ? "Add" : "Save")
                }
                .disabled(name.isEmpty || apiEndpoint.isEmpty || modelName.isEmpty)
            }
            .padding()
        }
        .padding()
        .frame(width: 500, height: 600)
        .onAppear {
            if case .edit(let profile) = mode {
                name = profile.name
                apiEndpoint = profile.apiEndpoint
                apiKey = profileManager.getAPIKey(for: profile.id) ?? ""
                modelName = profile.modelName
                temperature = profile.parameters.temperature
                maxTokens = profile.parameters.maxTokens
                topP = profile.parameters.topP
                frequencyPenalty = profile.parameters.frequencyPenalty
                presencePenalty = profile.parameters.presencePenalty
                isDefault = profile.isDefault
            }
        }
    }
    
    private var modeIsAdd: Bool {
        if case .add = mode {
            return true
        }
        return false
    }
    
    private func testConnection() {
        guard !apiEndpoint.isEmpty, !apiKey.isEmpty, !modelName.isEmpty else {
            return
        }
        
        isTestingConnection = true
        connectionTestResult = "Testing connection..."
        
        profileManager.testConnection(endpoint: apiEndpoint, key: apiKey, model: modelName) { result in
            DispatchQueue.main.async {
                isTestingConnection = false
                
                switch result {
                case .success:
                    connectionTestResult = "Connection successful!"
                    connectionTestSuccess = true
                case .failure(let error):
                    connectionTestResult = "Connection failed: \(error.localizedDescription)"
                    connectionTestSuccess = false
                }
            }
        }
    }
    
    private func saveProfile() {
        let parameters = ModelParameters(
            temperature: temperature,
            maxTokens: maxTokens,
            topP: topP,
            frequencyPenalty: frequencyPenalty,
            presencePenalty: presencePenalty
        )
        
        do {
            if case .add = mode {
                guard let url = URL(string: apiEndpoint) else {
                    connectionTestResult = "Invalid API endpoint URL"
                    connectionTestSuccess = false
                    return
                }
                
                _ = try profileManager.createProfile(
                    name: name,
                    apiEndpoint: url,
                    apiKey: apiKey,
                    modelName: modelName,
                    parameters: parameters,
                    isDefault: isDefault
                )
            } else if case .edit(let profile) = mode {
                guard let url = URL(string: apiEndpoint) else {
                    connectionTestResult = "Invalid API endpoint URL"
                    connectionTestSuccess = false
                    return
                }
                
                try profileManager.updateProfile(
                    id: profile.id,
                    name: name,
                    apiEndpoint: url,
                    apiKey: apiKey,
                    modelName: modelName,
                    parameters: parameters,
                    isDefault: isDefault
                )
            }
            
            presentationMode.wrappedValue.dismiss()
        } catch {
            connectionTestResult = "Error saving profile: \(error.localizedDescription)"
            connectionTestSuccess = false
        }
    }
}

// Preview provider for SwiftUI Canvas
struct ProfilesView_Previews: PreviewProvider {
    static var previews: some View {
        let keychainManager = KeychainManager()
        
        // Create a mock database manager that doesn't throw
        let databaseManager: DatabaseManager
        do {
            databaseManager = try DatabaseManager()
        } catch {
            fatalError("Failed to initialize DatabaseManager for preview: \(error.localizedDescription)")
        }
        
        let profileManager = ProfileManager(databaseManager: databaseManager, keychainManager: keychainManager)
        
        return ProfilesView(profileManager: profileManager)
    }
}
