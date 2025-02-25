import XCTest
import Combine
@testable import MacOSChatApp

class ModelConfigurationManagerTests: XCTestCase {
    
    var modelConfigManager: ModelConfigurationManager!
    var keychainManager: KeychainManager!
    var userDefaultsManager: UserDefaultsManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        
        // Create managers
        keychainManager = KeychainManager()
        userDefaultsManager = UserDefaultsManager()
        
        // Reset UserDefaults to ensure clean state
        userDefaultsManager.resetToDefaults()
        
        // Create model configuration manager
        modelConfigManager = ModelConfigurationManager(
            keychainManager: keychainManager,
            userDefaultsManager: userDefaultsManager
        )
        
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        modelConfigManager = nil
        userDefaultsManager = nil
        keychainManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        // Then
        XCTAssertEqual(modelConfigManager.apiEndpoint, "https://api.openai.com/v1/chat/completions")
        XCTAssertEqual(modelConfigManager.selectedModel, "gpt-3.5-turbo")
        XCTAssertEqual(modelConfigManager.temperature, 0.7)
        XCTAssertEqual(modelConfigManager.maxTokens, 2048)
        XCTAssertEqual(modelConfigManager.topP, 1.0)
        XCTAssertEqual(modelConfigManager.frequencyPenalty, 0.0)
        XCTAssertEqual(modelConfigManager.presencePenalty, 0.0)
        XCTAssertFalse(modelConfigManager.ollamaEnabled)
        XCTAssertEqual(modelConfigManager.ollamaEndpoint, "http://localhost:11434")
        XCTAssertEqual(modelConfigManager.availableModels.count, 2)
        XCTAssertTrue(modelConfigManager.availableModels.contains("gpt-3.5-turbo"))
        XCTAssertTrue(modelConfigManager.availableModels.contains("gpt-4"))
    }
    
    // MARK: - Parameter Tests
    
    func testGetCurrentParameters() {
        // Given
        modelConfigManager.temperature = 0.8
        modelConfigManager.maxTokens = 1024
        modelConfigManager.topP = 0.9
        modelConfigManager.frequencyPenalty = 0.1
        modelConfigManager.presencePenalty = 0.2
        
        // When
        let parameters = modelConfigManager.getCurrentParameters()
        
        // Then
        XCTAssertEqual(parameters.temperature, 0.8)
        XCTAssertEqual(parameters.maxTokens, 1024)
        XCTAssertEqual(parameters.topP, 0.9)
        XCTAssertEqual(parameters.frequencyPenalty, 0.1)
        XCTAssertEqual(parameters.presencePenalty, 0.2)
    }
    
    func testResetToDefaults() {
        // Given
        modelConfigManager.temperature = 0.8
        modelConfigManager.maxTokens = 1024
        modelConfigManager.topP = 0.9
        modelConfigManager.frequencyPenalty = 0.1
        modelConfigManager.presencePenalty = 0.2
        
        // When
        modelConfigManager.resetToDefaults()
        
        // Then
        XCTAssertEqual(modelConfigManager.temperature, 0.7)
        XCTAssertEqual(modelConfigManager.maxTokens, 2048)
        XCTAssertEqual(modelConfigManager.topP, 1.0)
        XCTAssertEqual(modelConfigManager.frequencyPenalty, 0.0)
        XCTAssertEqual(modelConfigManager.presencePenalty, 0.0)
    }
    
    // MARK: - Profile Tests
    
    func testLoadProfile() {
        // Given
        let profile = ModelProfile(
            id: "test-profile",
            name: "Test Profile",
            modelName: "gpt-4",
            apiEndpoint: "https://api.example.com/v1/chat/completions",
            isDefault: false,
            parameters: ModelParameters(
                temperature: 0.8,
                maxTokens: 1024,
                topP: 0.9,
                frequencyPenalty: 0.1,
                presencePenalty: 0.2
            )
        )
        
        // Save API key for this profile
        keychainManager.saveAPIKey("test-api-key", forProfileId: profile.id)
        
        // When
        modelConfigManager.loadProfile(profile)
        
        // Then
        XCTAssertEqual(modelConfigManager.apiEndpoint, "https://api.example.com/v1/chat/completions")
        XCTAssertEqual(modelConfigManager.selectedModel, "gpt-4")
        XCTAssertEqual(modelConfigManager.temperature, 0.8)
        XCTAssertEqual(modelConfigManager.maxTokens, 1024)
        XCTAssertEqual(modelConfigManager.topP, 0.9)
        XCTAssertEqual(modelConfigManager.frequencyPenalty, 0.1)
        XCTAssertEqual(modelConfigManager.presencePenalty, 0.2)
    }
    
    func testCreateProfileFromCurrentSettings() {
        // Given
        modelConfigManager.apiEndpoint = "https://api.example.com/v1/chat/completions"
        modelConfigManager.selectedModel = "gpt-4"
        modelConfigManager.temperature = 0.8
        modelConfigManager.maxTokens = 1024
        modelConfigManager.topP = 0.9
        modelConfigManager.frequencyPenalty = 0.1
        modelConfigManager.presencePenalty = 0.2
        
        // When
        let profile = modelConfigManager.createProfileFromCurrentSettings(name: "Test Profile")
        
        // Then
        XCTAssertEqual(profile.name, "Test Profile")
        XCTAssertEqual(profile.apiEndpoint, "https://api.example.com/v1/chat/completions")
        XCTAssertEqual(profile.modelName, "gpt-4")
        XCTAssertFalse(profile.isDefault)
        XCTAssertEqual(profile.parameters.temperature, 0.8)
        XCTAssertEqual(profile.parameters.maxTokens, 1024)
        XCTAssertEqual(profile.parameters.topP, 0.9)
        XCTAssertEqual(profile.parameters.frequencyPenalty, 0.1)
        XCTAssertEqual(profile.parameters.presencePenalty, 0.2)
    }
    
    // MARK: - Ollama Tests
    
    func testOllamaEnabledUpdatesAvailableModels() {
        // Given
        let expectation = XCTestExpectation(description: "Available models updated")
        
        modelConfigManager.$availableModels
            .dropFirst() // Skip initial value
            .sink { models in
                // Then
                XCTAssertTrue(models.contains("gpt-3.5-turbo"))
                XCTAssertTrue(models.contains("gpt-4"))
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        modelConfigManager.ollamaEnabled = true
        modelConfigManager.ollamaModels = ["llama2", "mistral"]
        modelConfigManager.updateAvailableModels()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testOllamaDisabledRemovesOllamaModels() {
        // Given
        modelConfigManager.ollamaEnabled = true
        modelConfigManager.ollamaModels = ["llama2", "mistral"]
        modelConfigManager.updateAvailableModels()
        
        // Verify that Ollama models are added when Ollama is enabled
        XCTAssertTrue(modelConfigManager.availableModels.contains("ollama:llama2"))
        XCTAssertTrue(modelConfigManager.availableModels.contains("ollama:mistral"))
        
        // When
        modelConfigManager.ollamaEnabled = false
        modelConfigManager.updateAvailableModels()
        
        // Then
        XCTAssertTrue(modelConfigManager.availableModels.contains("gpt-3.5-turbo"))
        XCTAssertTrue(modelConfigManager.availableModels.contains("gpt-4"))
        XCTAssertFalse(modelConfigManager.availableModels.contains("ollama:llama2"))
        XCTAssertFalse(modelConfigManager.availableModels.contains("ollama:mistral"))
    }
    
    func testSelectedModelUpdatedWhenOllamaDisabled() {
        // Given
        modelConfigManager.ollamaEnabled = true
        modelConfigManager.ollamaModels = ["llama2"]
        modelConfigManager.selectedModel = "ollama:llama2"
        
        // When
        modelConfigManager.ollamaEnabled = false
        modelConfigManager.updateAvailableModels()
        
        // Then
        XCTAssertEqual(modelConfigManager.selectedModel, "gpt-3.5-turbo")
    }
    
    // MARK: - UserDefaults Integration Tests
    
    func testUserDefaultsIntegration() {
        // Given
        modelConfigManager.apiEndpoint = "https://api.example.com/v1/chat/completions"
        modelConfigManager.selectedModel = "gpt-4"
        modelConfigManager.temperature = 0.8
        modelConfigManager.maxTokens = 1024
        modelConfigManager.topP = 0.9
        modelConfigManager.frequencyPenalty = 0.1
        modelConfigManager.presencePenalty = 0.2
        modelConfigManager.ollamaEnabled = true
        modelConfigManager.ollamaEndpoint = "http://example.com:11434"
        
        // When
        // Create a new instance to load from UserDefaults
        let newModelConfigManager = ModelConfigurationManager(
            keychainManager: keychainManager,
            userDefaultsManager: userDefaultsManager
        )
        
        // Then
        XCTAssertEqual(newModelConfigManager.apiEndpoint, "https://api.example.com/v1/chat/completions")
        XCTAssertEqual(newModelConfigManager.selectedModel, "gpt-4")
        XCTAssertEqual(newModelConfigManager.temperature, 0.8)
        XCTAssertEqual(newModelConfigManager.maxTokens, 1024)
        XCTAssertEqual(newModelConfigManager.topP, 0.9)
        XCTAssertEqual(newModelConfigManager.frequencyPenalty, 0.1)
        XCTAssertEqual(newModelConfigManager.presencePenalty, 0.2)
        XCTAssertTrue(newModelConfigManager.ollamaEnabled)
        XCTAssertEqual(newModelConfigManager.ollamaEndpoint, "http://example.com:11434")
    }
}
