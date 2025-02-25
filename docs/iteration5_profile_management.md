# Iteration 5: Profile Management

## Overview
This iteration focuses on implementing the profile management system, which allows users to create, edit, and switch between different model configurations. Each profile will store API endpoint, API key, model name, and parameter settings, enabling users to easily switch between different models or configurations.

## Objectives
- Implement the ProfileManager for handling profile operations
- Create the UI for profile management
- Implement secure API key storage using Keychain
- Add profile switching functionality
- Implement profile import/export
- Create unit tests for profile management

## Implementation Details

### 1. ProfileManager Implementation
1. Create the profile manager class:

```swift
import Foundation
import Combine

class ProfileManager: ObservableObject {
    @Published var profiles: [ModelProfile] = []
    @Published var selectedProfileId: String? = nil
    @Published var errorMessage: String? = nil
    
    private let databaseManager: DatabaseManager
    private let keychainManager: KeychainManager
    
    private var cancellables = Set<AnyCancellable>()
    
    init(databaseManager: DatabaseManager, keychainManager: KeychainManager) {
        self.databaseManager = databaseManager
        self.keychainManager = keychainManager
        
        loadProfiles()
    }
    
    func loadProfiles() {
        // Load profiles from database
        profiles = databaseManager.getAllProfiles()
        
        // Set selected profile to default, or first profile if no default
        if let defaultProfile = profiles.first(where: { $0.isDefault }) {
            selectedProfileId = defaultProfile.id
        } else if let firstProfile = profiles.first {
            selectedProfileId = firstProfile.id
        }
        
        // If no profiles exist, create a default one
        if profiles.isEmpty {
            createDefaultProfile()
        }
    }
    
    func createProfile(name: String, apiEndpoint: URL, apiKey: String, modelName: String, parameters: ModelParameters, isDefault: Bool = false) throws -> ModelProfile {
        let profileId = UUID().uuidString
        
        // Save API key to Keychain
        keychainManager.saveAPIKey(apiKey, forProfileId: profileId)
        
        // Create profile
        let profile = ModelProfile(
            id: profileId,
            name: name,
            apiEndpoint: apiEndpoint,
            apiKey: profileId, // Store reference to Keychain
            modelName: modelName,
            parameters: parameters,
            isDefault: isDefault
        )
        
        // Save to database
        try databaseManager.saveProfile(profile)
        
        // Add to list
        DispatchQueue.main.async {
            self.profiles.append(profile)
            
            // If this is the first profile or set as default, select it
            if self.profiles.count == 1 || isDefault {
                self.selectedProfileId = profileId
            }
            
            // Sort profiles by name
            self.profiles.sort { $0.name < $1.name }
        }
        
        return profile
    }
    
    func updateProfile(id: String, name: String, apiEndpoint: URL, apiKey: String?, modelName: String, parameters: ModelParameters, isDefault: Bool = false) throws {
        // Get existing profile
        guard let existingProfile = profiles.first(where: { $0.id == id }) else {
            throw ProfileError.notFound
        }
        
        // Update API key in Keychain if provided
        if let apiKey = apiKey, !apiKey.isEmpty {
            keychainManager.saveAPIKey(apiKey, forProfileId: id)
        }
        
        // Create updated profile
        let updatedProfile = ModelProfile(
            id: id,
            name: name,
            apiEndpoint: apiEndpoint,
            apiKey: existingProfile.apiKey, // Keep reference to Keychain
            modelName: modelName,
            parameters: parameters,
            isDefault: isDefault
        )
        
        // Save to database
        try databaseManager.updateProfile(updatedProfile)
        
        // Update in list
        DispatchQueue.main.async {
            if let index = self.profiles.firstIndex(where: { $0.id == id }) {
                self.profiles[index] = updatedProfile
            }
            
            // Sort profiles by name
            self.profiles.sort { $0.name < $1.name }
        }
    }
    
    func deleteProfile(id: String) throws {
        // Cannot delete the only profile
        if profiles.count <= 1 {
            throw ProfileError.cannotDeleteLastProfile
        }
        
        // Cannot delete the selected profile
        if id == selectedProfileId {
            throw ProfileError.cannotDeleteSelectedProfile
        }
        
        // Delete from database
        try databaseManager.deleteProfile(id: id)
        
        // Delete API key from Keychain
        keychainManager.deleteAPIKey(forProfileId: id)
        
        // Remove from list
        DispatchQueue.main.async {
            self.profiles.removeAll { $0.id == id }
        }
    }
    
    func setDefaultProfile(id: String) throws {
        // Get profile
        guard let profile = profiles.first(where: { $0.id == id }) else {
            throw ProfileError.notFound
        }
        
        // Set as default in database
        try databaseManager.setDefaultProfile(id: id)
        
        // Update in list
        DispatchQueue.main.async {
            // Update isDefault flag for all profiles
            for i in 0..<self.profiles.count {
                self.profiles[i].isDefault = (self.profiles[i].id == id)
            }
            
            // Select this profile
            self.selectedProfileId = id
        }
    }
    
    func selectProfile(id: String) {
        // Verify profile exists
        guard profiles.contains(where: { $0.id == id }) else {
            errorMessage = "Profile not found"
            return
        }
        
        // Set selected profile
        selectedProfileId = id
    }
    
    func getAPIKey(for profileId: String) -> String? {
        return keychainManager.getAPIKey(forProfileId: profileId)
    }
    
    func getSelectedProfile() -> ModelProfile? {
        guard let selectedProfileId = selectedProfileId else {
            return nil
        }
        
        return profiles.first { $0.id == selectedProfileId }
    }
    
    func duplicateProfile(id: String) throws -> ModelProfile {
        // Get profile to duplicate
        guard let profile = profiles.first(where: { $0.id == id }) else {
            throw ProfileError.notFound
        }
        
        // Get API key
        let apiKey = keychainManager.getAPIKey(forProfileId: id) ?? ""
        
        // Create new profile with same settings
        return try createProfile(
            name: "\(profile.name) (Copy)",
            apiEndpoint: profile.apiEndpoint,
            apiKey: apiKey,
            modelName: profile.modelName,
            parameters: profile.parameters,
            isDefault: false
        )
    }
    
    func testConnection(endpoint: String, key: String, model: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        // Create temporary API client to test connection
        guard let url = URL(string: endpoint) else {
            completion(.failure(ProfileError.invalidURL))
            return
        }
        
        let apiClient = APIClient(endpoint: url, apiKey: key)
        
        apiClient.testConnection { result in
            completion(result)
        }
    }
    
    func exportProfiles() -> URL? {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let fileName = "MacOSChatApp_Profiles.json"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        // Create export data
        var exportData: [[String: Any]] = []
        
        for profile in profiles {
            let apiKey = keychainManager.getAPIKey(forProfileId: profile.id) ?? ""
            
            let profileData: [String: Any] = [
                "name": profile.name,
                "apiEndpoint": profile.apiEndpoint.absoluteString,
                "apiKey": apiKey,
                "modelName": profile.modelName,
                "parameters": [
                    "temperature": profile.parameters.temperature,
                    "maxTokens": profile.parameters.maxTokens,
                    "topP": profile.parameters.topP,
                    "frequencyPenalty": profile.parameters.frequencyPenalty,
                    "presencePenalty": profile.parameters.presencePenalty
                ],
                "isDefault": profile.isDefault
            ]
            
            exportData.append(profileData)
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            try jsonData.write(to: fileURL)
            return fileURL
        } catch {
            errorMessage = "Failed to export profiles: \(error.localizedDescription)"
            return nil
        }
    }
    
    func importProfiles(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            
            guard let profilesData = jsonArray else {
                throw ProfileError.invalidImportData
            }
            
            for profileData in profilesData {
                guard let name = profileData["name"] as? String,
                      let apiEndpointString = profileData["apiEndpoint"] as? String,
                      let apiEndpoint = URL(string: apiEndpointString),
                      let apiKey = profileData["apiKey"] as? String,
                      let modelName = profileData["modelName"] as? String,
                      let parametersData = profileData["parameters"] as? [String: Any],
                      let temperature = parametersData["temperature"] as? Double,
                      let maxTokens = parametersData["maxTokens"] as? Int,
                      let topP = parametersData["topP"] as? Double,
                      let frequencyPenalty = parametersData["frequencyPenalty"] as? Double,
                      let presencePenalty = parametersData["presencePenalty"] as? Double,
                      let isDefault = profileData["isDefault"] as? Bool else {
                    continue
                }
                
                let parameters = ModelParameters(
                    temperature: temperature,
                    maxTokens: maxTokens,
                    topP: topP,
                    frequencyPenalty: frequencyPenalty,
                    presencePenalty: presencePenalty
                )
                
                // Check if profile with same name already exists
                if profiles.contains(where: { $0.name == name }) {
                    try createProfile(
                        name: "\(name) (Imported)",
                        apiEndpoint: apiEndpoint,
                        apiKey: apiKey,
                        modelName: modelName,
                        parameters: parameters,
                        isDefault: isDefault && profiles.isEmpty
                    )
                } else {
                    try createProfile(
                        name: name,
                        apiEndpoint: apiEndpoint,
                        apiKey: apiKey,
                        modelName: modelName,
                        parameters: parameters,
                        isDefault: isDefault && profiles.isEmpty
                    )
                }
            }
        } catch {
            errorMessage = "Failed to import profiles: \(error.localizedDescription)"
        }
    }
    
    private func createDefaultProfile() {
        do {
            // Create a default OpenAI profile
            try createProfile(
                name: "OpenAI GPT-3.5",
                apiEndpoint: URL(string: "https://api.openai.com/v1/chat/completions")!,
                apiKey: "",
                modelName: "gpt-3.5-turbo",
                parameters: ModelParameters(
                    temperature: 0.7,
                    maxTokens: 2048,
                    topP: 1.0,
                    frequencyPenalty: 0.0,
                    presencePenalty: 0.0
                ),
                isDefault: true
            )
        } catch {
            errorMessage = "Failed to create default profile: \(error.localizedDescription)"
        }
    }
}

enum ProfileError: Error {
    case notFound
    case cannotDeleteLastProfile
    case cannotDeleteSelectedProfile
    case invalidURL
    case invalidImportData
}
```

### 2. ProfilesView Implementation
1. Update the ProfilesView to use the ProfileManager:

```swift
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
            try profileManager.duplicateProfile(id: id)
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
```

2. Update the ProfileEditorView:

```swift
import SwiftUI

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
                    TextField("Profile Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("API Endpoint", text: $apiEndpoint)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    SecureField("API Key", text: $apiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Model Name", text: $modelName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Toggle("Set as Default Profile", isOn: $isDefault)
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
                
                Button(mode == .add ? "Add" : "Save") {
                    saveProfile()
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
                apiEndpoint = profile.apiEndpoint.absoluteString
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
    
    private var maxTokensDouble: Binding<Double> {
        Binding<Double>(
            get: { Double(maxTokens) },
            set: { maxTokens = Int($0) }
        )
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
                    return
                }
                
                try profileManager.createProfile(
                    name: name,
                    apiEndpoint: url,
                    apiKey: apiKey,
                    modelName: modelName,
                    parameters: parameters,
                    isDefault: isDefault
                )
            } else if case .edit(let profile) = mode {
                guard let url = URL(string: apiEndpoint) else {
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
```

### 3. Integration with ChatViewModel
1. Update the ChatViewModel to use profiles:

```swift
import Foundation
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let modelConfigManager: ModelConfigurationManager
    private let databaseManager: DatabaseManager
    private let documentHandler: DocumentHandler
    private let profileManager: ProfileManager
    
    private var currentConversationId: String?
    private var cancellables = Set<AnyCancellable>()
    
    init(modelConfigManager: ModelConfigurationManager, databaseManager: DatabaseManager, documentHandler: DocumentHandler, profileManager: ProfileManager) {
        self.modelConfigManager = modelConfigManager
        self.databaseManager = databaseManager
        self.documentHandler = documentHandler
        self.profileManager = profileManager
        
        // Observe profile changes
        profileManager.$selectedProfileId
            .sink { [weak self] _ in
                self?.updateAPIClientForSelectedProfile()
            }
            .store(in: &cancellables)
        
        loadOrCreateConversation()
        updateAPIClientForSelectedProfile()
    }
    
    private func updateAPIClientForSelectedProfile() {
        guard let profile = profileManager.getSelectedProfile() else {
            return
        }
        
        // Get API key from Keychain
        let apiKey = profileManager.getAPIKey(for: profile.id) ?? ""
        
        // Update API client configuration
        modelConfigManager.updateConfiguration(
            endpoint: profile.apiEndpoint,
            apiKey: apiKey,
            modelName: profile.modelName,
            parameters: profile.parameters
        )
        
        // If we have a current conversation, update its profile
        if let conversationId = currentConversationId {
            do {
                try databaseManager.updateConversationProfile(id: conversationId, profileId: profile.id)
            } catch {
                errorMessage = "Failed to update conversation profile: \(error.localizedDescription)"
            }
        }
    }
    
    // Rest of the ChatViewModel implementation remains the same
    // ...
}
```

2. Update the ModelConfigurationManager to handle profile-specific settings:

```swift
import Foundation
import Combine

extension ModelConfigurationManager {
    func updateConfiguration(endpoint: URL, apiKey: String, modelName: String, parameters: ModelParameters) {
        self.apiEndpoint = endpoint
        self.apiKey = apiKey
        self.selectedModel = modelName
        self.temperature = parameters.temperature
        self.maxTokens = parameters.maxTokens
        self.topP = parameters.topP
        self.frequencyPenalty = parameters.frequencyPenalty
        self.presencePenalty = parameters.presencePenalty
        
        // Update API client
        openAIClient.updateConfiguration(endpoint: endpoint, apiKey: apiKey)
    }
}
```

## Unit Tests
The following tests will verify that the profile management is implemented correctly:

### 1. ProfileManagerTests.swift
```swift
import XCTest
import Combine
@testable import MacOSChatApp

class ProfileManagerTests: XCTestCase {
    
    var profileManager: ProfileManager!
    var databaseManager: DatabaseManager!
    var keychainManager: KeychainManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        
        // Use in-memory database for testing
        databaseManager = try! DatabaseManager(inMemory: true)
        keychainManager = MockKeychainManager()
        profileManager = ProfileManager(databaseManager: databaseManager, keychainManager: keychainManager)
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        profileManager = nil
        keychainManager = nil
        databaseManager = nil
        super.tearDown()
    }
    
    func testCreateProfile() throws {
        // Given
        let name = "Test Profile"
        let apiEndpoint = URL(string: "https://api.example.com")!
        let apiKey = "test-api-key"
        let modelName = "gpt-4"
        let parameters = ModelParameters(
            temperature: 0.7,
            maxTokens: 2048,
            topP: 1.0,
            frequencyPenalty: 0.0,
            presencePenalty: 0.0
        )
        
        // When
        let profile = try profileManager.createProfile(
            name: name,
            apiEndpoint: apiEndpoint,
            apiKey: apiKey,
            modelName: modelName,
            parameters: parameters,
            isDefault: true
        )
        
        // Then
        XCTAssertEqual(profile.name, name)
        XCTAssertEqual(profile.apiEndpoint, apiEndpoint)
        XCTAssertEqual(profile.modelName, modelName)
        XCTAssertEqual(profile.parameters.temperature, parameters.temperature)
        XCTAssertTrue(profile.isDefault)
        
        // Verify profile was added to the list
        XCTAssertEqual(profileManager.profiles
