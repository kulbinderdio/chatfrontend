import Foundation
import Combine

class ProfileManager: ObservableObject {
    @Published var profiles: [ModelProfile] = []
    @Published var selectedProfileId: String? = nil
    @Published var errorMessage: String? = nil
    
    private let databaseManager: DatabaseManager
    private let keychainManager: KeychainManager
    
    private var cancellables = Set<AnyCancellable>()
    
    init(databaseManager: DatabaseManager, keychainManager: KeychainManager) {
        self.databaseManager = databaseManager
        self.keychainManager = keychainManager
        
        loadProfiles()
    }
    
    func loadProfiles() {
        // Load profiles from database
        profiles = databaseManager.getAllProfiles()
        
        // Set selected profile to default, or first profile if no default
        if let defaultProfile = profiles.first(where: { $0.isDefault }) {
            selectedProfileId = defaultProfile.id
        } else if let firstProfile = profiles.first {
            selectedProfileId = firstProfile.id
        }
        
        // If no profiles exist, create a default one
        if profiles.isEmpty {
            createDefaultProfile()
        }
    }
    
    func createProfile(name: String, apiEndpoint: URL, apiKey: String, modelName: String, parameters: ModelParameters, isDefault: Bool = false) throws -> ModelProfile {
        let profileId = UUID().uuidString
        
        // Save API key to Keychain
        keychainManager.saveAPIKey(apiKey, forProfileId: profileId)
        
        // Create profile
        let profile = ModelProfile(
            id: profileId,
            name: name,
            modelName: modelName,
            apiEndpoint: apiEndpoint.absoluteString,
            isDefault: isDefault,
            parameters: parameters
        )
        
        // Save to database
        try databaseManager.saveProfile(profile)
        
        // Add to list
        DispatchQueue.main.async {
            self.profiles.append(profile)
            
            // If this is the first profile or set as default, select it
            if self.profiles.count == 1 || isDefault {
                self.selectedProfileId = profileId
            }
            
            // Sort profiles by name
            self.profiles.sort { $0.name < $1.name }
        }
        
        return profile
    }
    
    func updateProfile(id: String, name: String, apiEndpoint: URL, apiKey: String?, modelName: String, parameters: ModelParameters, isDefault: Bool = false) throws {
        // Get existing profile
        guard profiles.first(where: { $0.id == id }) != nil else {
            throw ProfileError.notFound
        }
        
        // Update API key in Keychain if provided
        if let apiKey = apiKey, !apiKey.isEmpty {
            keychainManager.saveAPIKey(apiKey, forProfileId: id)
        }
        
        // Create updated profile
        let updatedProfile = ModelProfile(
            id: id,
            name: name,
            modelName: modelName,
            apiEndpoint: apiEndpoint.absoluteString,
            isDefault: isDefault,
            parameters: parameters
        )
        
        // Save to database
        try databaseManager.updateProfile(updatedProfile)
        
        // Update in list
        DispatchQueue.main.async {
            if let index = self.profiles.firstIndex(where: { $0.id == id }) {
                self.profiles[index] = updatedProfile
            }
            
            // Sort profiles by name
            self.profiles.sort { $0.name < $1.name }
        }
    }
    
    func deleteProfile(id: String) throws {
        // Cannot delete the only profile
        if profiles.count <= 1 {
            throw ProfileError.cannotDeleteLastProfile
        }
        
        // Cannot delete the selected profile
        if id == selectedProfileId {
            throw ProfileError.cannotDeleteSelectedProfile
        }
        
        // Delete from database
        try databaseManager.deleteProfile(id: id)
        
        // Delete API key from Keychain
        keychainManager.deleteAPIKey(forProfileId: id)
        
        // Remove from list
        DispatchQueue.main.async {
            self.profiles.removeAll { $0.id == id }
        }
    }
    
    func setDefaultProfile(id: String) throws {
        // Get profile
        guard profiles.first(where: { $0.id == id }) != nil else {
            throw ProfileError.notFound
        }
        
        // Set as default in database
        try databaseManager.setDefaultProfile(id: id)
        
        // Update in list
        DispatchQueue.main.async {
            // Update isDefault flag for all profiles
            for i in 0..<self.profiles.count {
                self.profiles[i].isDefault = (self.profiles[i].id == id)
            }
            
            // Select this profile
            self.selectedProfileId = id
        }
    }
    
    func selectProfile(id: String) {
        // Verify profile exists
        guard profiles.contains(where: { $0.id == id }) else {
            errorMessage = "Profile not found"
            return
        }
        
        // Set selected profile
        selectedProfileId = id
    }
    
    func getAPIKey(for profileId: String) -> String? {
        return keychainManager.getAPIKey(for: profileId)
    }
    
    func getSelectedProfile() -> ModelProfile? {
        guard let selectedProfileId = selectedProfileId else {
            return nil
        }
        
        return profiles.first { $0.id == selectedProfileId }
    }
    
    func duplicateProfile(id: String) throws -> ModelProfile {
        // Get profile to duplicate
        guard let profile = profiles.first(where: { $0.id == id }) else {
            throw ProfileError.notFound
        }
        
        // Get API key
        let apiKey = keychainManager.getAPIKey(for: profile.id) ?? ""
        
        // Create new profile with same settings
        return try createProfile(
            name: "\(profile.name) (Copy)",
            apiEndpoint: URL(string: profile.apiEndpoint)!,
            apiKey: apiKey,
            modelName: profile.modelName,
            parameters: profile.parameters,
            isDefault: false
        )
    }
    
    func testConnection(endpoint: String, key: String, model: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        // Create a test message to send to the API
        let testMessage = [Message(id: UUID().uuidString, role: "user", content: "Hello", timestamp: Date())]
        let testParameters = ModelParameters(temperature: 0.7, maxTokens: 10, topP: 1.0, frequencyPenalty: 0.0, presencePenalty: 0.0)
        
        // Check if this is an Ollama model
        if model.hasPrefix("ollama:") {
            // For Ollama, we need to append the API path
            var ollamaEndpoint = endpoint
            if !ollamaEndpoint.hasSuffix("/") {
                ollamaEndpoint += "/"
            }
            ollamaEndpoint += "api/generate"
            
            guard let url = URL(string: ollamaEndpoint) else {
                completion(.failure(ProfileError.invalidURL))
                return
            }
            
            let ollamaModelName = model.replacingOccurrences(of: "ollama:", with: "")
            
            // Convert OpenAI-style messages to Ollama format
            let prompt = testMessage.map { "\($0.role): \($0.content)" }.joined(separator: "\n")
            
            // Create the request body
            let body: [String: Any] = [
                "model": ollamaModelName,
                "prompt": prompt,
                "stream": false
            ]
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            let session = URLSession.shared
            let task = session.dataTask(with: request) { _, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                            completion(.success(true))
                        } else {
                            let error = NSError(domain: "OllamaError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"])
                            completion(.failure(error))
                        }
                    } else {
                        completion(.success(true)) // If we got a response but couldn't cast it, assume success
                    }
                }
            }
            task.resume()
        } else {
            // For OpenAI and other API providers
            
            // Correct the OpenRouter endpoint if needed
            var correctedEndpoint = endpoint
            if correctedEndpoint.contains("openrouter.ai") && !correctedEndpoint.contains("/chat/completions") {
                if correctedEndpoint.contains("/api/v1") {
                    correctedEndpoint = correctedEndpoint + "/chat/completions"
                }
            }
            
            guard let url = URL(string: correctedEndpoint) else {
                completion(.failure(ProfileError.invalidURL))
                return
            }
            
            // Create the request body
            let messagesJSON = testMessage.map { message -> [String: String] in
                return [
                    "role": message.role,
                    "content": message.content
                ]
            }
            
            let body: [String: Any] = [
                "model": model,
                "messages": messagesJSON,
                "temperature": testParameters.temperature,
                "max_tokens": testParameters.maxTokens,
                "top_p": testParameters.topP,
                "frequency_penalty": testParameters.frequencyPenalty,
                "presence_penalty": testParameters.presencePenalty
            ]
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            let session = URLSession.shared
            let task = session.dataTask(with: request) { _, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        // 200-299 means success, 401 means the server is reachable but the API key is invalid
                        if httpResponse.statusCode == 401 || (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
                            completion(.success(true))
                        } else {
                            let error = NSError(domain: "APIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"])
                            completion(.failure(error))
                        }
                    } else {
                        completion(.success(true)) // If we got a response but couldn't cast it, assume success
                    }
                }
            }
            task.resume()
        }
    }
    
    func exportProfiles() -> URL? {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let fileName = "MacOSChatApp_Profiles.json"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        // Create export data
        var exportData: [[String: Any]] = []
        
        for profile in profiles {
            let apiKey = keychainManager.getAPIKey(for: profile.id) ?? ""
            
            let profileData: [String: Any] = [
                "name": profile.name,
                "apiEndpoint": profile.apiEndpoint,
                "apiKey": apiKey,
                "modelName": profile.modelName,
                "parameters": [
                    "temperature": profile.parameters.temperature,
                    "maxTokens": profile.parameters.maxTokens,
                    "topP": profile.parameters.topP,
                    "frequencyPenalty": profile.parameters.frequencyPenalty,
                    "presencePenalty": profile.parameters.presencePenalty
                ],
                "isDefault": profile.isDefault
            ]
            
            exportData.append(profileData)
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            try jsonData.write(to: fileURL)
            return fileURL
        } catch {
            errorMessage = "Failed to export profiles: \(error.localizedDescription)"
            return nil
        }
    }
    
    func importProfiles(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            
            guard let profilesData = jsonArray else {
                throw ProfileError.invalidImportData
            }
            
            for profileData in profilesData {
                guard let name = profileData["name"] as? String,
                      let apiEndpointString = profileData["apiEndpoint"] as? String,
                      let apiEndpoint = URL(string: apiEndpointString),
                      let apiKey = profileData["apiKey"] as? String,
                      let modelName = profileData["modelName"] as? String,
                      let parametersData = profileData["parameters"] as? [String: Any],
                      let temperature = parametersData["temperature"] as? Double,
                      let maxTokens = parametersData["maxTokens"] as? Int,
                      let topP = parametersData["topP"] as? Double,
                      let frequencyPenalty = parametersData["frequencyPenalty"] as? Double,
                      let presencePenalty = parametersData["presencePenalty"] as? Double,
                      let isDefault = profileData["isDefault"] as? Bool else {
                    continue
                }
                
                let parameters = ModelParameters(
                    temperature: temperature,
                    maxTokens: maxTokens,
                    topP: topP,
                    frequencyPenalty: frequencyPenalty,
                    presencePenalty: presencePenalty
                )
                
                // Check if profile with same name already exists
                if profiles.contains(where: { $0.name == name }) {
                    _ = try? createProfile(
                        name: "\(name) (Imported)",
                        apiEndpoint: apiEndpoint,
                        apiKey: apiKey,
                        modelName: modelName,
                        parameters: parameters,
                        isDefault: isDefault && profiles.isEmpty
                    )
                } else {
                    _ = try? createProfile(
                        name: name,
                        apiEndpoint: apiEndpoint,
                        apiKey: apiKey,
                        modelName: modelName,
                        parameters: parameters,
                        isDefault: isDefault && profiles.isEmpty
                    )
                }
            }
        } catch {
            errorMessage = "Failed to import profiles: \(error.localizedDescription)"
        }
    }
    
    func deleteAllProfiles() {
        // Get a copy of the profiles list
        let profilesCopy = profiles
        
        // Find the default profile
        let defaultProfile = profilesCopy.first(where: { $0.isDefault })
        
        // Clear the profiles list and selected profile ID first
        DispatchQueue.main.async {
            self.profiles = []
            self.selectedProfileId = nil
        }
        
        // Delete all non-default profiles from the database
        for profile in profilesCopy where !profile.isDefault {
            // Delete API key from Keychain
            keychainManager.deleteAPIKey(forProfileId: profile.id)
            
            // Try to delete the profile from the database
            do {
                try databaseManager.deleteProfile(id: profile.id)
            } catch {
                // Silently continue
            }
        }
        
        // If there's a default profile, update it to have default settings
        if let defaultProfile = defaultProfile {
            // Delete API key from Keychain
            keychainManager.deleteAPIKey(forProfileId: defaultProfile.id)
            
            // Update the default profile with default settings
            do {
                try databaseManager.updateProfile(ModelProfile(
                    id: defaultProfile.id,
                    name: "OpenAI GPT-3.5",
                    modelName: "gpt-3.5-turbo",
                    apiEndpoint: "https://api.openai.com/v1/chat/completions",
                    isDefault: true,
                    parameters: ModelParameters(
                        temperature: 0.7,
                        maxTokens: 2048,
                        topP: 1.0,
                        frequencyPenalty: 0.0,
                        presencePenalty: 0.0
                    )
                ))
            } catch {
                // If updating fails, create a new default profile
                createDefaultProfile()
            }
        } else {
            // If there's no default profile, create one
            createDefaultProfile()
        }
        
        // Reload profiles
        loadProfiles()
    }
    
    private func createDefaultProfile() {
        do {
            // Create a default OpenAI profile
            _ = try createProfile(
                name: "OpenAI GPT-3.5",
                apiEndpoint: URL(string: "https://api.openai.com/v1/chat/completions")!,
                apiKey: "",
                modelName: "gpt-3.5-turbo",
                parameters: ModelParameters(
                    temperature: 0.7,
                    maxTokens: 2048,
                    topP: 1.0,
                    frequencyPenalty: 0.0,
                    presencePenalty: 0.0
                ),
                isDefault: true
            )
        } catch {
            errorMessage = "Failed to create default profile: \(error.localizedDescription)"
        }
    }
}

enum ProfileError: Error, LocalizedError {
    case notFound
    case cannotDeleteLastProfile
    case cannotDeleteSelectedProfile
    case invalidURL
    case invalidImportData
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Profile not found"
        case .cannotDeleteLastProfile:
            return "Cannot delete the last profile"
        case .cannotDeleteSelectedProfile:
            return "Cannot delete the selected profile"
        case .invalidURL:
            return "Invalid URL"
        case .invalidImportData:
            return "Invalid import data"
        }
    }
