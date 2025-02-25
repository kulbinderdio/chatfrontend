import Foundation
import Combine

class UserDefaultsManager: ObservableObject {
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
        static let darkModeEnabled = "dark_mode_enabled"
        static let fontSize = "font_size"
        static let defaultProfileId = "default_profile_id"
        static let ollamaEnabled = "ollama_enabled"
        static let ollamaEndpoint = "ollama_endpoint"
    }
    
    // MARK: - API Configuration
    
    func saveAPIEndpoint(_ endpoint: String) {
        defaults.set(endpoint, forKey: DefaultsKey.apiEndpoint)
    }
    
    func getAPIEndpoint() -> String {
        return defaults.string(forKey: DefaultsKey.apiEndpoint) ?? "https://api.openai.com/v1/chat/completions"
    }
    
    func saveSelectedModel(_ model: String) {
        defaults.set(model, forKey: DefaultsKey.selectedModel)
    }
    
    func getSelectedModel() -> String {
        return defaults.string(forKey: DefaultsKey.selectedModel) ?? "gpt-3.5-turbo"
    }
    
    // MARK: - Model Parameters
    
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
    
    // MARK: - Appearance
    
    func saveDarkModeEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: DefaultsKey.darkModeEnabled)
    }
    
    func getDarkModeEnabled() -> Bool {
        return defaults.bool(forKey: DefaultsKey.darkModeEnabled)
    }
    
    func saveFontSize(_ size: String) {
        defaults.set(size, forKey: DefaultsKey.fontSize)
    }
    
    func getFontSize() -> String {
        return defaults.string(forKey: DefaultsKey.fontSize) ?? "medium"
    }
    
    // MARK: - Profiles
    
    func saveDefaultProfileId(_ id: String) {
        defaults.set(id, forKey: DefaultsKey.defaultProfileId)
    }
    
    func getDefaultProfileId() -> String? {
        return defaults.string(forKey: DefaultsKey.defaultProfileId)
    }
    
    // MARK: - Ollama
    
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
}
