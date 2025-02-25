import Foundation

class UserDefaultsManager {
    private let defaults = UserDefaults.standard
    
    // Keys
    private enum DefaultsKey {
        static let apiEndpoint = "api_endpoint"
        static let selectedModel = "selected_model"
        static let temperature = "temperature"
        static let maxTokens = "max_tokens"
        static let topP = "top_p"
        static let frequencyPenalty = "frequency_penalty"
        static let presencePenalty = "presence_penalty"
        static let ollamaEnabled = "ollama_enabled"
        static let ollamaEndpoint = "ollama_endpoint"
        static let defaultProfileId = "default_profile_id"
        static let darkModeEnabled = "dark_mode_enabled"
    }
    
    // MARK: - API Configuration
    
    func saveAPIEndpoint(_ endpoint: String) {
        defaults.set(endpoint, forKey: DefaultsKey.apiEndpoint)
    }
    
    func getAPIEndpoint() -> String {
        return defaults.string(forKey: DefaultsKey.apiEndpoint) ?? "https://api.openai.com/v1/chat/completions"
    }
    
    // MARK: - Model Configuration
    
    func saveSelectedModel(_ model: String) {
        defaults.set(model, forKey: DefaultsKey.selectedModel)
    }
    
    func getSelectedModel() -> String {
        return defaults.string(forKey: DefaultsKey.selectedModel) ?? "gpt-3.5-turbo"
    }
    
    func saveTemperature(_ temperature: Double) {
        defaults.set(temperature, forKey: DefaultsKey.temperature)
    }
    
    func getTemperature() -> Double {
        return defaults.double(forKey: DefaultsKey.temperature)
    }
    
    func saveMaxTokens(_ maxTokens: Int) {
        defaults.set(maxTokens, forKey: DefaultsKey.maxTokens)
    }
    
    func getMaxTokens() -> Int {
        return defaults.integer(forKey: DefaultsKey.maxTokens)
    }
    
    func saveTopP(_ topP: Double) {
        defaults.set(topP, forKey: DefaultsKey.topP)
    }
    
    func getTopP() -> Double {
        return defaults.double(forKey: DefaultsKey.topP)
    }
    
    func saveFrequencyPenalty(_ frequencyPenalty: Double) {
        defaults.set(frequencyPenalty, forKey: DefaultsKey.frequencyPenalty)
    }
    
    func getFrequencyPenalty() -> Double {
        return defaults.double(forKey: DefaultsKey.frequencyPenalty)
    }
    
    func savePresencePenalty(_ presencePenalty: Double) {
        defaults.set(presencePenalty, forKey: DefaultsKey.presencePenalty)
    }
    
    func getPresencePenalty() -> Double {
        return defaults.double(forKey: DefaultsKey.presencePenalty)
    }
    
    // MARK: - Ollama Configuration
    
    func saveOllamaEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: DefaultsKey.ollamaEnabled)
    }
    
    func getOllamaEnabled() -> Bool {
        return defaults.bool(forKey: DefaultsKey.ollamaEnabled)
    }
    
    func saveOllamaEndpoint(_ endpoint: String) {
        defaults.set(endpoint, forKey: DefaultsKey.ollamaEndpoint)
    }
    
    func getOllamaEndpoint() -> String {
        return defaults.string(forKey: DefaultsKey.ollamaEndpoint) ?? "http://localhost:11434"
    }
    
    // MARK: - Profile Configuration
    
    func saveDefaultProfileId(_ profileId: String) {
        defaults.set(profileId, forKey: DefaultsKey.defaultProfileId)
    }
    
    func getDefaultProfileId() -> String? {
        return defaults.string(forKey: DefaultsKey.defaultProfileId)
    }
    
    // MARK: - Appearance Configuration
    
    func saveDarkModeEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: DefaultsKey.darkModeEnabled)
    }
    
    func getDarkModeEnabled() -> Bool {
        return defaults.bool(forKey: DefaultsKey.darkModeEnabled)
    }
    
    // MARK: - Reset
    
    func resetToDefaults() {
        let keys = [
            DefaultsKey.apiEndpoint,
            DefaultsKey.selectedModel,
            DefaultsKey.temperature,
            DefaultsKey.maxTokens,
            DefaultsKey.topP,
            DefaultsKey.frequencyPenalty,
            DefaultsKey.presencePenalty,
            DefaultsKey.ollamaEnabled,
            DefaultsKey.ollamaEndpoint,
            DefaultsKey.defaultProfileId,
            DefaultsKey.darkModeEnabled
        ]
        
        for key in keys {
            defaults.removeObject(forKey: key)
        }
    }
}
