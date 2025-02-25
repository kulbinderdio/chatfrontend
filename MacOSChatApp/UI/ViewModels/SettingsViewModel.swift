import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    // API Configuration
    @Published var apiEndpoint: String = "https://api.openai.com/v1/chat/completions"
    @Published var apiKey: String = ""
    
    // Ollama Configuration
    @Published var ollamaEnabled: Bool = false
    @Published var ollamaEndpoint: String = "http://localhost:11434"
    
    // Model Configuration
    @Published var selectedModel: String = "gpt-3.5-turbo"
    @Published var availableModels: [String] = ["gpt-3.5-turbo", "gpt-4"]
    
    // Model Parameters
    @Published var temperature: Double = 0.7
    @Published var maxTokens: Int = 2048
    @Published var topP: Double = 1.0
    @Published var frequencyPenalty: Double = 0.0
    @Published var presencePenalty: Double = 0.0
    
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
    
    // These will be injected in later iterations
    private var keychainManager: KeychainManager?
    private var userDefaultsManager: UserDefaultsManager?
    private var databaseManager: Any? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // This is a placeholder implementation
        // In a real implementation, we would load settings from UserDefaults and Keychain
        
        // Load default profiles
        profiles = ModelProfile.defaultProfiles
        
        // Set up publishers to save changes
        setupPublishers()
    }
    
    // MARK: - Publishers
    
    private func setupPublishers() {
        // In a real implementation, these publishers would save changes to UserDefaults and Keychain
        
        $apiEndpoint
            .dropFirst()
            .sink { [weak self] endpoint in
                self?.userDefaultsManager?.saveAPIEndpoint(endpoint)
            }
            .store(in: &cancellables)
        
        $apiKey
            .dropFirst()
            .sink { [weak self] key in
                self?.keychainManager?.saveAPIKey(key)
            }
            .store(in: &cancellables)
        
        $ollamaEnabled
            .dropFirst()
            .sink { [weak self] enabled in
                self?.userDefaultsManager?.saveOllamaEnabled(enabled)
            }
            .store(in: &cancellables)
        
        $ollamaEndpoint
            .dropFirst()
            .sink { [weak self] endpoint in
                self?.userDefaultsManager?.saveOllamaEndpoint(endpoint)
            }
            .store(in: &cancellables)
        
        $selectedModel
            .dropFirst()
            .sink { [weak self] model in
                self?.userDefaultsManager?.saveSelectedModel(model)
            }
            .store(in: &cancellables)
        
        $temperature
            .dropFirst()
            .sink { [weak self] temperature in
                self?.userDefaultsManager?.saveTemperature(temperature)
            }
            .store(in: &cancellables)
        
        $maxTokens
            .dropFirst()
            .sink { [weak self] maxTokens in
                self?.userDefaultsManager?.saveMaxTokens(maxTokens)
            }
            .store(in: &cancellables)
        
        $topP
            .dropFirst()
            .sink { [weak self] topP in
                self?.userDefaultsManager?.saveTopP(topP)
            }
            .store(in: &cancellables)
        
        $frequencyPenalty
            .dropFirst()
            .sink { [weak self] frequencyPenalty in
                self?.userDefaultsManager?.saveFrequencyPenalty(frequencyPenalty)
            }
            .store(in: &cancellables)
        
        $presencePenalty
            .dropFirst()
            .sink { [weak self] presencePenalty in
                self?.userDefaultsManager?.savePresencePenalty(presencePenalty)
            }
            .store(in: &cancellables)
        
        $useSystemAppearance
            .dropFirst()
            .sink { [weak self] useSystemAppearance in
                // Save to UserDefaults
            }
            .store(in: &cancellables)
        
        $darkModeEnabled
            .dropFirst()
            .sink { [weak self] darkModeEnabled in
                self?.userDefaultsManager?.saveDarkModeEnabled(darkModeEnabled)
            }
            .store(in: &cancellables)
        
        $fontSize
            .dropFirst()
            .sink { [weak self] fontSize in
                // Save to UserDefaults
            }
            .store(in: &cancellables)
        
        $launchAtLogin
            .dropFirst()
            .sink { [weak self] launchAtLogin in
                // Save to UserDefaults
            }
            .store(in: &cancellables)
        
        $showInDock
            .dropFirst()
            .sink { [weak self] showInDock in
                // Save to UserDefaults
            }
            .store(in: &cancellables)
    }
    
    // MARK: - API Configuration
    
    func updateAPIConfig(endpoint: String, key: String) {
        apiEndpoint = endpoint
        apiKey = key
    }
    
    // MARK: - Model Parameters
    
    func resetToDefaults() {
        temperature = 0.7
        maxTokens = 2048
        topP = 1.0
        frequencyPenalty = 0.0
        presencePenalty = 0.0
    }
    
    // MARK: - Profile Management
    
    func addProfile(name: String, apiEndpoint: String, apiKey: String, modelName: String, parameters: ModelParameters) {
        let profile = ModelProfile(
            name: name,
            modelName: modelName,
            apiEndpoint: apiEndpoint,
            isDefault: profiles.isEmpty,
            parameters: parameters
        )
        
        profiles.append(profile)
        
        // In a real implementation, we would save the profile to Keychain
        keychainManager?.saveProfile(profile)
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
            
            profiles[index] = updatedProfile
            
            // In a real implementation, we would save the profile to Keychain
            keychainManager?.saveProfile(updatedProfile)
        }
    }
    
    func deleteProfile(id: String) {
        if let index = profiles.firstIndex(where: { $0.id == id }) {
            // Don't delete the default profile
            if profiles[index].isDefault {
                return
            }
            
            profiles.remove(at: index)
            
            // In a real implementation, we would delete the profile from Keychain
            keychainManager?.deleteProfile(id: id)
        }
    }
    
    func setDefaultProfile(id: String) {
        for i in 0..<profiles.count {
            profiles[i].isDefault = profiles[i].id == id
        }
    }
    
    func getAPIKey(for profileId: String) -> String? {
        // In a real implementation, we would get the API key from Keychain
        return "test-api-key"
    }
    
    func testConnection(endpoint: String, key: String, model: String) {
        // This is a placeholder implementation
        // In a real implementation, we would test the connection to the API
        
        isLoading = true
        
        // Simulate delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoading = false
            
            // Simulate success
            // In a real implementation, we would check the response from the API
            self?.errorMessage = nil
        }
    }
    
    // MARK: - Advanced Settings
    
    func clearConversationHistory() {
        // This is a placeholder implementation
        // In a real implementation, we would clear the conversation history from the database
    }
    
    func resetAllSettings() {
        // This is a placeholder implementation
        // In a real implementation, we would reset all settings to defaults
        
        apiEndpoint = "https://api.openai.com/v1/chat/completions"
        apiKey = ""
        ollamaEnabled = false
        ollamaEndpoint = "http://localhost:11434"
        selectedModel = "gpt-3.5-turbo"
        temperature = 0.7
        maxTokens = 2048
        topP = 1.0
        frequencyPenalty = 0.0
        presencePenalty = 0.0
        useSystemAppearance = true
        darkModeEnabled = false
        fontSize = "medium"
        launchAtLogin = false
        showInDock = true
    }
    
    // MARK: - Computed Properties
    
    var maxTokensDouble: Double {
        get { Double(maxTokens) }
        set { maxTokens = Int(newValue) }
    }
}
