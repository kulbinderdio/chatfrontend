import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    // Model Configuration Manager
    private let modelConfigManager: ModelConfigurationManager
    
    // API Configuration
    @Published var apiEndpoint: String
    @Published var apiKey: String
    
    // Ollama Configuration
    @Published var ollamaEnabled: Bool
    @Published var ollamaEndpoint: String
    
    // Model Configuration
    @Published var selectedModel: String
    @Published var availableModels: [String]
    
    // Model Parameters
    @Published var temperature: Double
    @Published var maxTokens: Int
    @Published var topP: Double
    @Published var frequencyPenalty: Double
    @Published var presencePenalty: Double
    
    // Appearance
    @Published var useSystemAppearance: Bool = true
    @Published var darkModeEnabled: Bool = false
    @Published var fontSize: String = "medium"
    
    // Advanced
    @Published var launchAtLogin: Bool = false
    @Published var showInDock: Bool = true
    
    // Profiles
    @Published var profiles: [ModelProfile] = []
    
    // Status
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Dependencies
    private let keychainManager: KeychainManager
    private let userDefaultsManager: UserDefaultsManager
    private let databaseManager: DatabaseManager
    
    private var cancellables = Set<AnyCancellable>()
    
    init(modelConfigManager: ModelConfigurationManager, keychainManager: KeychainManager, userDefaultsManager: UserDefaultsManager, databaseManager: DatabaseManager) {
        self.modelConfigManager = modelConfigManager
        self.keychainManager = keychainManager
        self.userDefaultsManager = userDefaultsManager
        self.databaseManager = databaseManager
        
        // Initialize with values from ModelConfigurationManager
        self.apiEndpoint = modelConfigManager.apiEndpoint
        self.apiKey = modelConfigManager.apiKey
        self.selectedModel = modelConfigManager.selectedModel
        self.availableModels = modelConfigManager.availableModels
        
        self.temperature = modelConfigManager.temperature
        self.maxTokens = modelConfigManager.maxTokens
        self.topP = modelConfigManager.topP
        self.frequencyPenalty = modelConfigManager.frequencyPenalty
        self.presencePenalty = modelConfigManager.presencePenalty
        
        self.ollamaEnabled = modelConfigManager.ollamaEnabled
        self.ollamaEndpoint = modelConfigManager.ollamaEndpoint
        
        // Load profiles
        loadProfiles()
        
        // Set up publishers to sync with ModelConfigurationManager
        setupPublishers()
    }
    
    // MARK: - Publishers
    
    private func setupPublishers() {
        // Bind API endpoint to ModelConfigurationManager
        $apiEndpoint
            .dropFirst()
            .sink { [weak self] endpoint in
                self?.modelConfigManager.apiEndpoint = endpoint
            }
            .store(in: &cancellables)
        
        // Bind API key to ModelConfigurationManager
        $apiKey
            .dropFirst()
            .sink { [weak self] key in
                self?.modelConfigManager.apiKey = key
            }
            .store(in: &cancellables)
        
        // Bind selected model to ModelConfigurationManager
        $selectedModel
            .dropFirst()
            .sink { [weak self] model in
                self?.modelConfigManager.selectedModel = model
            }
            .store(in: &cancellables)
        
        // Bind temperature to ModelConfigurationManager
        $temperature
            .dropFirst()
            .sink { [weak self] value in
                self?.modelConfigManager.temperature = value
            }
            .store(in: &cancellables)
        
        // Bind max tokens to ModelConfigurationManager
        $maxTokens
            .dropFirst()
            .sink { [weak self] value in
                self?.modelConfigManager.maxTokens = value
            }
            .store(in: &cancellables)
        
        // Bind top-p to ModelConfigurationManager
        $topP
            .dropFirst()
            .sink { [weak self] value in
                self?.modelConfigManager.topP = value
            }
            .store(in: &cancellables)
        
        // Bind frequency penalty to ModelConfigurationManager
        $frequencyPenalty
            .dropFirst()
            .sink { [weak self] value in
                self?.modelConfigManager.frequencyPenalty = value
            }
            .store(in: &cancellables)
        
        // Bind presence penalty to ModelConfigurationManager
        $presencePenalty
            .dropFirst()
            .sink { [weak self] value in
                self?.modelConfigManager.presencePenalty = value
            }
            .store(in: &cancellables)
        
        // Bind Ollama enabled to ModelConfigurationManager
        $ollamaEnabled
            .dropFirst()
            .sink { [weak self] enabled in
                self?.modelConfigManager.ollamaEnabled = enabled
            }
            .store(in: &cancellables)
        
        // Bind Ollama endpoint to ModelConfigurationManager
        $ollamaEndpoint
            .dropFirst()
            .sink { [weak self] endpoint in
                self?.modelConfigManager.ollamaEndpoint = endpoint
            }
            .store(in: &cancellables)
        
        // Bind dark mode to UserDefaultsManager
        $darkModeEnabled
            .dropFirst()
            .sink { [weak self] darkModeEnabled in
                self?.userDefaultsManager.saveDarkModeEnabled(darkModeEnabled)
            }
            .store(in: &cancellables)
        
        // Listen for changes in ModelConfigurationManager
        modelConfigManager.$availableModels
            .sink { [weak self] models in
                self?.availableModels = models
            }
            .store(in: &cancellables)
        
        modelConfigManager.$errorMessage
            .sink { [weak self] error in
                self?.errorMessage = error
            }
            .store(in: &cancellables)
        
        modelConfigManager.$isLoading
            .sink { [weak self] loading in
                self?.isLoading = loading
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Profile Management
    
    private func loadProfiles() {
        profiles = keychainManager.getAllProfiles()
        
        // If no profiles exist, create a default one
        if profiles.isEmpty {
            let defaultProfile = ModelProfile.defaultProfiles[0]
            keychainManager.saveProfile(defaultProfile)
            profiles = [defaultProfile]
        }
    }
    
    func addProfile(name: String, apiEndpoint: String, apiKey: String, modelName: String, parameters: ModelParameters) {
        let profile = ModelProfile(
            name: name,
            modelName: modelName,
            apiEndpoint: apiEndpoint,
            isDefault: profiles.isEmpty,
            parameters: parameters
        )
        
        // Save API key for this profile
        keychainManager.saveAPIKey(apiKey, forProfileId: profile.id)
        
        // Save profile
        keychainManager.saveProfile(profile)
        
        // Update profiles list
        profiles.append(profile)
    }
    
    func updateProfile(id: String, name: String, apiEndpoint: String, apiKey: String, modelName: String, parameters: ModelParameters) {
        if let index = profiles.firstIndex(where: { $0.id == id }) {
            let isDefault = profiles[index].isDefault
            
            let updatedProfile = ModelProfile(
                id: id,
                name: name,
                modelName: modelName,
                apiEndpoint: apiEndpoint,
                isDefault: isDefault,
                parameters: parameters
            )
            
            // Save API key for this profile
            keychainManager.saveAPIKey(apiKey, forProfileId: id)
            
            // Save profile
            keychainManager.saveProfile(updatedProfile)
            
            // Update profiles list
            profiles[index] = updatedProfile
            
            // If this is the default profile, update current settings
            if isDefault {
                loadProfile(updatedProfile)
            }
        }
    }
    
    func deleteProfile(id: String) {
        if let index = profiles.firstIndex(where: { $0.id == id }) {
            // Don't delete the default profile
            if profiles[index].isDefault {
                return
            }
            
            // Delete API key for this profile
            keychainManager.deleteAPIKey(forProfileId: id)
            
            // Delete profile
            keychainManager.deleteProfile(id: id)
            
            // Update profiles list
            profiles.remove(at: index)
        }
    }
    
    func setDefaultProfile(id: String) {
        // Update default status in profiles
        for i in 0..<profiles.count {
            let wasDefault = profiles[i].isDefault
            let willBeDefault = profiles[i].id == id
            
            if wasDefault != willBeDefault {
                // Create updated profile with new default status
                let updatedProfile = ModelProfile(
                    id: profiles[i].id,
                    name: profiles[i].name,
                    modelName: profiles[i].modelName,
                    apiEndpoint: profiles[i].apiEndpoint,
                    isDefault: willBeDefault,
                    parameters: profiles[i].parameters
                )
                
                // Save updated profile
                keychainManager.saveProfile(updatedProfile)
                
                // Update profiles list
                profiles[i] = updatedProfile
                
                // If this is the new default profile, load it
                if willBeDefault {
                    loadProfile(updatedProfile)
                }
            }
        }
        
        // Save default profile ID
        userDefaultsManager.saveDefaultProfileId(id)
    }
    
    func loadProfile(_ profile: ModelProfile) {
        // Load profile settings into ModelConfigurationManager
        modelConfigManager.loadProfile(profile)
        
        // Update local properties
        apiEndpoint = profile.apiEndpoint
        apiKey = keychainManager.getAPIKey(for: profile.id) ?? ""
        selectedModel = profile.modelName
        
        temperature = profile.parameters.temperature
        maxTokens = profile.parameters.maxTokens
        topP = profile.parameters.topP
        frequencyPenalty = profile.parameters.frequencyPenalty
        presencePenalty = profile.parameters.presencePenalty
    }
    
    func getAPIKey(for profileId: String) -> String? {
        return keychainManager.getAPIKey(for: profileId)
    }
    
    // MARK: - API Configuration
    
    func updateAPIConfig(endpoint: String, key: String) {
        apiEndpoint = endpoint
        apiKey = key
    }
    
    // MARK: - Connection Testing
    
    func testConnection(endpoint: String, key: String, model: String) {
        isLoading = true
        errorMessage = nil
        
        // Create temporary API client for testing
        let parameters = ModelParameters()
        let apiClient = APIClient(apiEndpoint: endpoint, apiKey: key, modelName: model, parameters: parameters)
        
        apiClient.testConnection { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success:
                    self?.errorMessage = nil
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Model Parameters
    
    func resetToDefaults() {
        modelConfigManager.resetToDefaults()
        
        // Update local properties
        temperature = modelConfigManager.temperature
        maxTokens = modelConfigManager.maxTokens
        topP = modelConfigManager.topP
        frequencyPenalty = modelConfigManager.frequencyPenalty
        presencePenalty = modelConfigManager.presencePenalty
    }
    
    // MARK: - Advanced Settings
    
    func clearConversationHistory() {
        // Get all conversations
        let conversations = databaseManager.getAllConversations()
        
        // Delete each conversation
        for conversation in conversations {
            do {
                try databaseManager.deleteConversation(id: conversation.id)
            } catch {
                print("Failed to delete conversation \(conversation.id): \(error.localizedDescription)")
                errorMessage = "Failed to delete some conversations"
            }
        }
    }
    
    func resetAllSettings() {
        // Reset model configuration
        modelConfigManager.resetToDefaults()
        
        // Reset API configuration
        apiEndpoint = "https://api.openai.com/v1/chat/completions"
        apiKey = ""
        selectedModel = "gpt-3.5-turbo"
        
        // Reset Ollama configuration
        ollamaEnabled = false
        ollamaEndpoint = "http://localhost:11434"
        
        // Reset appearance settings
        useSystemAppearance = true
        darkModeEnabled = false
        fontSize = "medium"
        
        // Reset advanced settings
        launchAtLogin = false
        showInDock = true
        
        // Update ModelConfigurationManager
        modelConfigManager.apiEndpoint = apiEndpoint
        modelConfigManager.apiKey = apiKey
        modelConfigManager.selectedModel = selectedModel
        modelConfigManager.ollamaEnabled = ollamaEnabled
        modelConfigManager.ollamaEndpoint = ollamaEndpoint
    }
    
    // MARK: - Computed Properties
    
    var maxTokensDouble: Double {
        get { Double(maxTokens) }
        set { maxTokens = Int(newValue) }
    }
}
