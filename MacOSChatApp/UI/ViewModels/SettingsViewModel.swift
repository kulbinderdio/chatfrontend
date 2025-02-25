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
    
    // These will be injected in later iterations
    private var keychainManager: Any? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // This is a placeholder implementation
        // In a real implementation, we would load settings from UserDefaults and Keychain
        
        // Set up publishers to save changes
        setupPublishers()
    }
    
    private func setupPublishers() {
        // In a real implementation, these publishers would save changes to UserDefaults and Keychain
        
        $apiEndpoint
            .dropFirst()
            .sink { _ in
                // Save to UserDefaults
            }
            .store(in: &cancellables)
        
        $apiKey
            .dropFirst()
            .sink { _ in
                // Save to Keychain
            }
            .store(in: &cancellables)
        
        $ollamaEnabled
            .dropFirst()
            .sink { _ in
                // Save to UserDefaults
            }
            .store(in: &cancellables)
        
        $ollamaEndpoint
            .dropFirst()
            .sink { _ in
                // Save to UserDefaults
            }
            .store(in: &cancellables)
        
        $selectedModel
            .dropFirst()
            .sink { _ in
                // Save to UserDefaults
            }
            .store(in: &cancellables)
        
        $temperature
            .dropFirst()
            .sink { _ in
                // Save to UserDefaults
            }
            .store(in: &cancellables)
        
        $maxTokens
            .dropFirst()
            .sink { _ in
                // Save to UserDefaults
            }
            .store(in: &cancellables)
        
        $topP
            .dropFirst()
            .sink { _ in
                // Save to UserDefaults
            }
            .store(in: &cancellables)
        
        $frequencyPenalty
            .dropFirst()
            .sink { _ in
                // Save to UserDefaults
            }
            .store(in: &cancellables)
        
        $presencePenalty
            .dropFirst()
            .sink { _ in
                // Save to UserDefaults
            }
            .store(in: &cancellables)
    }
    
    func updateAPIConfig(endpoint: String, key: String) {
        apiEndpoint = endpoint
        apiKey = key
    }
    
    func resetToDefaults() {
        temperature = 0.7
        maxTokens = 2048
        topP = 1.0
        frequencyPenalty = 0.0
        presencePenalty = 0.0
    }
}
