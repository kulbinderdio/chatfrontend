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
    
    // Status
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Dependencies
    private let keychainManager: KeychainManager
    private let userDefaultsManager: UserDefaultsManager
    private let databaseManager: DatabaseManager
    private let profileManager: ProfileManager
    
    private var cancellables = Set<AnyCancellable>()
    
    init(modelConfigManager: ModelConfigurationManager, keychainManager: KeychainManager, userDefaultsManager: UserDefaultsManager, databaseManager: DatabaseManager, profileManager: ProfileManager) {
        self.modelConfigManager = modelConfigManager
        self.keychainManager = keychainManager
        self.userDefaultsManager = userDefaultsManager
        self.databaseManager = databaseManager
        self.profileManager = profileManager
        
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
    
    // MARK: - API Configuration
    
    func updateAPIConfig(endpoint: String, key: String) {
        apiEndpoint = endpoint
        apiKey = key
    }
    
    // MARK: - Connection Testing
    
    func testConnection(endpoint: String, key: String, model: String) {
        isLoading = true
        errorMessage = nil
        
        // Check if this is an Ollama model
        if model.hasPrefix("ollama:") {
            // For Ollama, we don't need an API key
            let ollamaEndpoint = ollamaEndpoint
            let ollamaModelName = model.replacingOccurrences(of: "ollama:", with: "")
            
            let ollamaClient = OllamaAPIClient(endpoint: ollamaEndpoint, modelName: ollamaModelName)
            
            ollamaClient.isEndpointReachable { [weak self] isReachable in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if isReachable {
                        self?.errorMessage = nil
                    } else {
                        self?.errorMessage = "Could not connect to Ollama server. Please check the endpoint URL."
                    }
                }
            }
        } else {
            // For OpenAI and other API providers
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
        
        // Post notification to refresh conversation list
        NotificationCenter.default.post(name: Notification.Name("ConversationHistoryCleared"), object: nil)
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
