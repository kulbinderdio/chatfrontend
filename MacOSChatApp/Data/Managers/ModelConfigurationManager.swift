import Foundation
import Combine

class ModelConfigurationManager: ObservableObject {
    // Published properties for UI binding
    @Published var apiEndpoint: String
    @Published var apiKey: String
    @Published var selectedModel: String
    @Published var availableModels: [String]
    
    // Model parameters
    @Published var temperature: Double
    @Published var maxTokens: Int
    @Published var topP: Double
    @Published var frequencyPenalty: Double
    @Published var presencePenalty: Double
    
    // Ollama configuration
    @Published var ollamaEnabled: Bool
    @Published var ollamaEndpoint: String
    @Published var ollamaModels: [String]
    
    // Status
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Default values
    private let defaultTemperature: Double = 0.7
    private let defaultMaxTokens: Int = 2048
    private let defaultTopP: Double = 1.0
    private let defaultFrequencyPenalty: Double = 0.0
    private let defaultPresencePenalty: Double = 0.0
    
    // Dependencies
    private let keychainManager: KeychainManager
    private let userDefaultsManager: UserDefaultsManager
    
    // API clients
    private var openAIClient: APIClient?
    private var ollamaClient: OllamaAPIClient?
    
    // Publishers
    private var cancellables = Set<AnyCancellable>()
    
    init(keychainManager: KeychainManager, userDefaultsManager: UserDefaultsManager) {
        self.keychainManager = keychainManager
        self.userDefaultsManager = userDefaultsManager
        
        // Initialize all published properties first
        self.apiEndpoint = userDefaultsManager.getAPIEndpoint()
        self.apiKey = keychainManager.getAPIKey() ?? ""
        self.selectedModel = userDefaultsManager.getSelectedModel()
        self.availableModels = ["gpt-3.5-turbo", "gpt-4"]
        
        // Initialize model parameters
        var temp = userDefaultsManager.getTemperature()
        if temp == 0 { temp = defaultTemperature }
        self.temperature = temp
        
        var tokens = userDefaultsManager.getMaxTokens()
        if tokens == 0 { tokens = defaultMaxTokens }
        self.maxTokens = tokens
        
        var tp = userDefaultsManager.getTopP()
        if tp == 0 { tp = defaultTopP }
        self.topP = tp
        
        var freqPenalty = userDefaultsManager.getFrequencyPenalty()
        if freqPenalty == 0 { freqPenalty = defaultFrequencyPenalty }
        self.frequencyPenalty = freqPenalty
        
        var presPenalty = userDefaultsManager.getPresencePenalty()
        if presPenalty == 0 { presPenalty = defaultPresencePenalty }
        self.presencePenalty = presPenalty
        
        // Initialize Ollama configuration
        self.ollamaEnabled = userDefaultsManager.getOllamaEnabled()
        self.ollamaEndpoint = userDefaultsManager.getOllamaEndpoint()
        self.ollamaModels = []
        
        // Initialize API clients
        initializeAPIClients()
        
        // Set up publishers to save changes
        setupPublishers()
        
        // Load Ollama models if enabled
        if ollamaEnabled {
            loadOllamaModels()
        }
    }
    
    // MARK: - Initialization
    
    private func initializeAPIClients() {
        // Initialize OpenAI client
        openAIClient = APIClient(
            apiEndpoint: apiEndpoint,
            apiKey: apiKey,
            modelName: selectedModel,
            parameters: getCurrentParameters()
        )
        
        // Initialize Ollama client if enabled
        if ollamaEnabled {
            ollamaClient = OllamaAPIClient(
                endpoint: ollamaEndpoint,
                modelName: selectedModel.replacingOccurrences(of: "ollama:", with: "")
            )
        }
    }
    
    private func setupPublishers() {
        // Save API endpoint when it changes
        $apiEndpoint
            .dropFirst()
            .sink { [weak self] endpoint in
                self?.userDefaultsManager.saveAPIEndpoint(endpoint)
                self?.updateOpenAIClient()
            }
            .store(in: &cancellables)
        
        // Save API key when it changes
        $apiKey
            .dropFirst()
            .sink { [weak self] key in
                self?.keychainManager.saveAPIKey(key)
                self?.updateOpenAIClient()
            }
            .store(in: &cancellables)
        
        // Save selected model when it changes
        $selectedModel
            .dropFirst()
            .sink { [weak self] model in
                self?.userDefaultsManager.saveSelectedModel(model)
                self?.updateClients()
            }
            .store(in: &cancellables)
        
        // Save temperature when it changes
        $temperature
            .dropFirst()
            .sink { [weak self] value in
                self?.userDefaultsManager.saveTemperature(value)
            }
            .store(in: &cancellables)
        
        // Save max tokens when it changes
        $maxTokens
            .dropFirst()
            .sink { [weak self] value in
                self?.userDefaultsManager.saveMaxTokens(value)
            }
            .store(in: &cancellables)
        
        // Save top-p when it changes
        $topP
            .dropFirst()
            .sink { [weak self] value in
                self?.userDefaultsManager.saveTopP(value)
            }
            .store(in: &cancellables)
        
        // Save frequency penalty when it changes
        $frequencyPenalty
            .dropFirst()
            .sink { [weak self] value in
                self?.userDefaultsManager.saveFrequencyPenalty(value)
            }
            .store(in: &cancellables)
        
        // Save presence penalty when it changes
        $presencePenalty
            .dropFirst()
            .sink { [weak self] value in
                self?.userDefaultsManager.savePresencePenalty(value)
            }
            .store(in: &cancellables)
        
        // Save Ollama enabled when it changes
        $ollamaEnabled
            .dropFirst()
            .sink { [weak self] enabled in
                self?.userDefaultsManager.saveOllamaEnabled(enabled)
                
                if enabled {
                    self?.initializeOllamaClient()
                    self?.loadOllamaModels()
                } else {
                    self?.ollamaClient = nil
                    self?.updateAvailableModels()
                }
            }
            .store(in: &cancellables)
        
        // Save Ollama endpoint when it changes
        $ollamaEndpoint
            .dropFirst()
            .sink { [weak self] endpoint in
                self?.userDefaultsManager.saveOllamaEndpoint(endpoint)
                
                if self?.ollamaEnabled == true {
                    self?.updateOllamaClient()
                    self?.loadOllamaModels()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Client Updates
    
    private func updateOpenAIClient() {
        openAIClient?.updateConfiguration(
            apiEndpoint: apiEndpoint,
            apiKey: apiKey,
            modelName: selectedModel,
            parameters: getCurrentParameters()
        )
    }
    
    private func updateOllamaClient() {
        ollamaClient?.updateEndpoint(endpoint: ollamaEndpoint)
        
        if selectedModel.hasPrefix("ollama:") {
            let modelName = selectedModel.replacingOccurrences(of: "ollama:", with: "")
            ollamaClient?.updateModelName(modelName: modelName)
        }
    }
    
    private func updateClients() {
        updateOpenAIClient()
        
        if selectedModel.hasPrefix("ollama:") {
            let modelName = selectedModel.replacingOccurrences(of: "ollama:", with: "")
            ollamaClient?.updateModelName(modelName: modelName)
        }
    }
    
    private func initializeOllamaClient() {
        let modelName = selectedModel.hasPrefix("ollama:") 
            ? selectedModel.replacingOccurrences(of: "ollama:", with: "")
            : "llama2" // Default model
        
        ollamaClient = OllamaAPIClient(
            endpoint: ollamaEndpoint,
            modelName: modelName
        )
    }
    
    // MARK: - Ollama Models
    
    private func loadOllamaModels() {
        guard ollamaEnabled, let ollamaClient = ollamaClient else {
            return
        }
        
        isLoading = true
        
        ollamaClient.getAvailableModels()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] models in
                    self?.ollamaModels = models
                    self?.updateAvailableModels()
                }
            )
            .store(in: &cancellables)
    }
    
    func updateAvailableModels() {
        // Start with OpenAI models
        var models = ["gpt-3.5-turbo", "gpt-4"]
        
        // Add Ollama models if enabled
        if ollamaEnabled {
            let ollamaModelsWithPrefix = ollamaModels.map { "ollama:\($0)" }
            models.append(contentsOf: ollamaModelsWithPrefix)
        }
        
        // Update available models
        availableModels = models
        
        // If selected model is an Ollama model but Ollama is disabled, switch to default
        if selectedModel.hasPrefix("ollama:") && !ollamaEnabled {
            selectedModel = "gpt-3.5-turbo"
        }
    }
    
    // MARK: - Parameters
    
    func getCurrentParameters() -> ModelParameters {
        return ModelParameters(
            temperature: temperature,
            maxTokens: maxTokens,
            topP: topP,
            frequencyPenalty: frequencyPenalty,
            presencePenalty: presencePenalty
        )
    }
    
    func resetToDefaults() {
        temperature = defaultTemperature
        maxTokens = defaultMaxTokens
        topP = defaultTopP
        frequencyPenalty = defaultFrequencyPenalty
        presencePenalty = defaultPresencePenalty
    }
    
    // MARK: - Message Sending
    
    func sendMessage(messages: [Message], completion: @escaping (Result<Message, APIClientError>) -> Void) {
        let parameters = getCurrentParameters()
        
        if selectedModel.hasPrefix("ollama:") && ollamaEnabled && ollamaClient != nil {
            ollamaClient?.sendMessage(messages: messages, parameters: parameters, completion: completion)
        } else if let openAIClient = openAIClient {
            openAIClient.sendMessage(messages: messages, parameters: parameters, completion: completion)
        } else {
            completion(.failure(.unknownError))
        }
    }
    
    func sendMessage(messages: [Message]) -> AnyPublisher<Message, APIClientError> {
        let parameters = getCurrentParameters()
        
        if selectedModel.hasPrefix("ollama:") && ollamaEnabled && ollamaClient != nil {
            return ollamaClient!.sendMessage(messages: messages, parameters: parameters)
        } else if let openAIClient = openAIClient {
            return openAIClient.sendMessage(messages: messages, parameters: parameters)
        } else {
            return Fail(error: APIClientError.unknownError).eraseToAnyPublisher()
        }
    }
    
    func streamMessage(messages: [Message]) -> AnyPublisher<String, APIClientError> {
        let parameters = getCurrentParameters()
        
        if selectedModel.hasPrefix("ollama:") && ollamaEnabled && ollamaClient != nil {
            return ollamaClient!.streamMessage(messages: messages, parameters: parameters)
        } else if let openAIClient = openAIClient {
            return openAIClient.streamMessage(messages: messages, parameters: parameters)
        } else {
            return Fail(error: APIClientError.unknownError).eraseToAnyPublisher()
        }
    }
    
    // MARK: - Connection Testing
    
    func testConnection(completion: @escaping (Result<Bool, APIClientError>) -> Void) {
        if selectedModel.hasPrefix("ollama:") && ollamaEnabled && ollamaClient != nil {
            // For Ollama, first check if the endpoint is reachable
            ollamaClient?.isEndpointReachable { isReachable in
                if isReachable {
                    completion(.success(true))
                } else {
                    completion(.failure(.requestFailed(NSError(domain: "OllamaError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not connect to Ollama server. Please check the endpoint URL."]))))
                }
            }
        } else if let openAIClient = openAIClient {
            openAIClient.testConnection(completion: completion)
        } else {
            completion(.failure(.unknownError))
        }
    }
    
    // MARK: - Profile Management
    
    func loadProfile(_ profile: ModelProfile) {
        apiEndpoint = profile.apiEndpoint
        apiKey = keychainManager.getAPIKey(for: profile.id) ?? ""
        selectedModel = profile.modelName
        
        temperature = profile.parameters.temperature
        maxTokens = profile.parameters.maxTokens
        topP = profile.parameters.topP
        frequencyPenalty = profile.parameters.frequencyPenalty
        presencePenalty = profile.parameters.presencePenalty
        
        updateClients()
    }
    
    func createProfileFromCurrentSettings(name: String) -> ModelProfile {
        return ModelProfile(
            name: name,
            modelName: selectedModel,
            apiEndpoint: apiEndpoint,
            isDefault: false,
            parameters: getCurrentParameters()
        )
    }
    
    func updateConfiguration(endpoint: URL, apiKey: String, modelName: String, parameters: ModelParameters) {
        self.apiEndpoint = endpoint.absoluteString
        self.apiKey = apiKey
        self.selectedModel = modelName
        self.temperature = parameters.temperature
        self.maxTokens = parameters.maxTokens
        self.topP = parameters.topP
        self.frequencyPenalty = parameters.frequencyPenalty
        self.presencePenalty = parameters.presencePenalty
        
        // Update API client
        openAIClient?.updateConfiguration(
            apiEndpoint: endpoint.absoluteString,
            apiKey: apiKey,
            modelName: modelName,
            parameters: parameters
        )
    }
}
