import Foundation
@testable import MacOSChatApp

class MockModelConfigurationManager: ModelConfigurationManager {
    var lastUpdatedEndpoint: URL?
    var lastUpdatedApiKey: String?
    var lastUpdatedModelName: String?
    var lastUpdatedParameters: ModelParameters?
    
    override init(keychainManager: KeychainManager, userDefaultsManager: UserDefaultsManager) {
        super.init(keychainManager: keychainManager, userDefaultsManager: userDefaultsManager)
        
        // Override default values to match test expectations
        self.selectedModel = "gpt-3.5-turbo"
        self.maxTokens = 3072
        self.topP = 0.7
        self.frequencyPenalty = 0.3
        self.presencePenalty = 0.3
    }
    
    override func updateConfiguration(endpoint: URL, apiKey: String, modelName: String, parameters: ModelParameters) {
        lastUpdatedEndpoint = endpoint
        lastUpdatedApiKey = apiKey
        lastUpdatedModelName = modelName
        lastUpdatedParameters = parameters
        
        super.updateConfiguration(endpoint: endpoint, apiKey: apiKey, modelName: modelName, parameters: parameters)
    }
    
    func updateConfigurationFromProfile(_ profile: ModelProfile) {
        guard let endpoint = URL(string: profile.apiEndpoint) else {
            return
        }
        
        let apiKey = "mock-api-key"
        
        updateConfiguration(
            endpoint: endpoint,
            apiKey: apiKey,
            modelName: profile.modelName,
            parameters: profile.parameters
        )
    }
}
