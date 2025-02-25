import Foundation

struct ModelProfile: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var modelName: String
    var apiEndpoint: String
    var isDefault: Bool
    var parameters: ModelParameters
    
    init(id: String, name: String, modelName: String, apiEndpoint: String, isDefault: Bool, parameters: ModelParameters) {
        self.id = id
        self.name = name
        self.modelName = modelName
        self.apiEndpoint = apiEndpoint
        self.isDefault = isDefault
        self.parameters = parameters
    }
    
    // Convenience initializer with auto-generated ID
    init(name: String, modelName: String, apiEndpoint: String, isDefault: Bool = false, parameters: ModelParameters = ModelParameters()) {
        self.id = UUID().uuidString
        self.name = name
        self.modelName = modelName
        self.apiEndpoint = apiEndpoint
        self.isDefault = isDefault
        self.parameters = parameters
    }
    
    // Codable conformance
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case modelName
        case apiEndpoint
        case isDefault
        case parameters
    }
    
    // Equatable conformance
    static func == (lhs: ModelProfile, rhs: ModelProfile) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.modelName == rhs.modelName &&
               lhs.apiEndpoint == rhs.apiEndpoint &&
               lhs.isDefault == rhs.isDefault &&
               lhs.parameters == rhs.parameters
    }
}

struct ModelParameters: Codable, Equatable {
    var temperature: Double
    var maxTokens: Int
    var topP: Double
    var frequencyPenalty: Double
    var presencePenalty: Double
    
    init(temperature: Double = 0.7,
         maxTokens: Int = 2048,
         topP: Double = 1.0,
         frequencyPenalty: Double = 0.0,
         presencePenalty: Double = 0.0) {
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.topP = topP
        self.frequencyPenalty = frequencyPenalty
        self.presencePenalty = presencePenalty
    }
    
    // Codable conformance
    enum CodingKeys: String, CodingKey {
        case temperature
        case maxTokens
        case topP
        case frequencyPenalty
        case presencePenalty
    }
    
    // Equatable conformance
    static func == (lhs: ModelParameters, rhs: ModelParameters) -> Bool {
        return lhs.temperature == rhs.temperature &&
               lhs.maxTokens == rhs.maxTokens &&
               lhs.topP == rhs.topP &&
               lhs.frequencyPenalty == rhs.frequencyPenalty &&
               lhs.presencePenalty == rhs.presencePenalty
    }
}

// Extension for API compatibility
extension ModelParameters {
    var apiRepresentation: [String: Any] {
        return [
            "temperature": temperature,
            "max_tokens": maxTokens,
            "top_p": topP,
            "frequency_penalty": frequencyPenalty,
            "presence_penalty": presencePenalty
        ]
    }
}

// Default profiles
extension ModelProfile {
    static let defaultProfiles: [ModelProfile] = [
        ModelProfile(
            name: "Default GPT-3.5",
            modelName: "gpt-3.5-turbo",
            apiEndpoint: "https://api.openai.com/v1/chat/completions",
            isDefault: true,
            parameters: ModelParameters()
        ),
        ModelProfile(
            name: "GPT-4",
            modelName: "gpt-4",
            apiEndpoint: "https://api.openai.com/v1/chat/completions",
            isDefault: false,
            parameters: ModelParameters()
        ),
        ModelProfile(
            name: "Ollama - Llama2",
            modelName: "llama2",
            apiEndpoint: "http://localhost:11434/api/chat",
            isDefault: false,
            parameters: ModelParameters()
        )
    ]
}
