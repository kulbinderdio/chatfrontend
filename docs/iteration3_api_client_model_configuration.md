# Iteration 3: API Client & Model Configuration

## Overview
This iteration focuses on implementing the API client for communicating with OpenAI-compatible endpoints and the model configuration management system. These components will handle the core functionality of sending requests to AI models and managing their configuration parameters.

## Objectives
- Implement the APIClient for communicating with OpenAI-compatible endpoints
- Create the ModelConfigurationManager for managing model settings
- Implement streaming response handling
- Add support for Ollama integration
- Implement error handling and retry mechanisms
- Create unit tests for API client and model configuration

## Implementation Details

### 1. APIClient Implementation
1. Create the core API client class:

```swift
import Foundation
import Alamofire
import SwiftyJSON
import Combine

enum APIClientError: Error {
    case invalidURL
    case invalidResponse
    case requestFailed(Error)
    case rateLimited
    case authenticationFailed
    case serverError(Int)
    case unknownError
}

class APIClient {
    private let session: Session
    private var apiEndpoint: URL
    private var apiKey: String
    
    private var cancellables = Set<AnyCancellable>()
    
    init(endpoint: URL, apiKey: String) {
        self.apiEndpoint = endpoint
        self.apiKey = apiKey
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 300
        
        self.session = Session(configuration: configuration)
    }
    
    func updateConfiguration(endpoint: URL, apiKey: String) {
        self.apiEndpoint = endpoint
        self.apiKey = apiKey
    }
    
    func sendMessage(messages: [Message], parameters: ModelParameters, model: String) -> AnyPublisher<String, APIClientError> {
        let request = createRequest(messages: messages, parameters: parameters, model: model)
        
        return Future<String, APIClientError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknownError))
                return
            }
            
            self.session.request(request)
                .validate()
                .responseJSON { response in
                    switch response.result {
                    case .success(let value):
                        let json = JSON(value)
                        if let content = json["choices"][0]["message"]["content"].string {
                            promise(.success(content))
                        } else {
                            promise(.failure(.invalidResponse))
                        }
                        
                    case .failure(let error):
                        if let statusCode = response.response?.statusCode {
                            switch statusCode {
                            case 401:
                                promise(.failure(.authenticationFailed))
                            case 429:
                                promise(.failure(.rateLimited))
                            case 500...599:
                                promise(.failure(.serverError(statusCode)))
                            default:
                                promise(.failure(.requestFailed(error)))
                            }
                        } else {
                            promise(.failure(.requestFailed(error)))
                        }
                    }
                }
        }
        .eraseToAnyPublisher()
    }
    
    func streamMessage(messages: [Message], parameters: ModelParameters, model: String) -> AnyPublisher<String, APIClientError> {
        let request = createStreamRequest(messages: messages, parameters: parameters, model: model)
        
        return session.streamRequest(request)
            .publishData()
            .tryMap { response -> String in
                guard let data = response.data else {
                    throw APIClientError.invalidResponse
                }
                
                // Process SSE data format
                let text = String(data: data, encoding: .utf8) ?? ""
                if text.hasPrefix("data: ") {
                    let jsonText = text.dropFirst(6)
                    if jsonText.trimmingCharacters(in: .whitespacesAndNewlines) == "[DONE]" {
                        return ""
                    }
                    
                    if let data = jsonText.data(using: .utf8),
                       let json = try? JSON(data: data),
                       let content = json["choices"][0]["delta"]["content"].string {
                        return content
                    }
                }
                
                return ""
            }
            .mapError { error in
                if let apiError = error as? APIClientError {
                    return apiError
                }
                return .requestFailed(error)
            }
            .filter { !$0.isEmpty }
            .eraseToAnyPublisher()
    }
    
    func createRequest(messages: [Message], parameters: ModelParameters, model: String) -> URLRequest {
        var request = URLRequest(url: apiEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let messagesJSON = messages.map { message -> [String: String] in
            return [
                "role": message.role,
                "content": message.content
            ]
        }
        
        let body: [String: Any] = [
            "model": model,
            "messages": messagesJSON,
            "temperature": parameters.temperature,
            "max_tokens": parameters.maxTokens,
            "top_p": parameters.topP,
            "frequency_penalty": parameters.frequencyPenalty,
            "presence_penalty": parameters.presencePenalty
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        return request
    }
    
    func createStreamRequest(messages: [Message], parameters: ModelParameters, model: String) -> URLRequest {
        var request = createRequest(messages: messages, parameters: parameters, model: model)
        
        // Add stream parameter
        var body = try? JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any]
        body?["stream"] = true
        request.httpBody = try? JSONSerialization.data(withJSONObject: body ?? [:])
        
        return request
    }
    
    func testConnection(completion: @escaping (Result<Bool, APIClientError>) -> Void) {
        let testMessage = [Message(id: UUID().uuidString, role: "user", content: "Hello", timestamp: Date())]
        let testParameters = ModelParameters(temperature: 0.7, maxTokens: 10, topP: 1.0, frequencyPenalty: 0.0, presencePenalty: 0.0)
        let testModel = "gpt-3.5-turbo"
        
        let request = createRequest(messages: testMessage, parameters: testParameters, model: testModel)
        
        session.request(request)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success:
                    completion(.success(true))
                case .failure(let error):
                    if let statusCode = response.response?.statusCode {
                        switch statusCode {
                        case 401:
                            completion(.failure(.authenticationFailed))
                        case 429:
                            completion(.failure(.rateLimited))
                        case 500...599:
                            completion(.failure(.serverError(statusCode)))
                        default:
                            completion(.failure(.requestFailed(error)))
                        }
                    } else {
                        completion(.failure(.requestFailed(error)))
                    }
                }
            }
    }
}
```

2. Implement Ollama API integration:

```swift
class OllamaAPIClient {
    private let session: Session
    private var apiEndpoint: URL
    
    private var cancellables = Set<AnyCancellable>()
    
    init(endpoint: URL) {
        self.apiEndpoint = endpoint
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 300
        
        self.session = Session(configuration: configuration)
    }
    
    func updateEndpoint(endpoint: URL) {
        self.apiEndpoint = endpoint
    }
    
    func sendMessage(messages: [Message], parameters: ModelParameters, model: String) -> AnyPublisher<String, APIClientError> {
        let request = createRequest(messages: messages, parameters: parameters, model: model)
        
        return Future<String, APIClientError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknownError))
                return
            }
            
            self.session.request(request)
                .validate()
                .responseJSON { response in
                    switch response.result {
                    case .success(let value):
                        let json = JSON(value)
                        if let content = json["response"].string {
                            promise(.success(content))
                        } else {
                            promise(.failure(.invalidResponse))
                        }
                        
                    case .failure(let error):
                        if let statusCode = response.response?.statusCode {
                            switch statusCode {
                            case 500...599:
                                promise(.failure(.serverError(statusCode)))
                            default:
                                promise(.failure(.requestFailed(error)))
                            }
                        } else {
                            promise(.failure(.requestFailed(error)))
                        }
                    }
                }
        }
        .eraseToAnyPublisher()
    }
    
    func streamMessage(messages: [Message], parameters: ModelParameters, model: String) -> AnyPublisher<String, APIClientError> {
        let request = createRequest(messages: messages, parameters: parameters, model: model)
        
        return session.streamRequest(request)
            .publishData()
            .tryMap { response -> String in
                guard let data = response.data else {
                    throw APIClientError.invalidResponse
                }
                
                let text = String(data: data, encoding: .utf8) ?? ""
                if let data = text.data(using: .utf8),
                   let json = try? JSON(data: data),
                   let content = json["response"].string {
                    return content
                }
                
                return ""
            }
            .mapError { error in
                if let apiError = error as? APIClientError {
                    return apiError
                }
                return .requestFailed(error)
            }
            .filter { !$0.isEmpty }
            .eraseToAnyPublisher()
    }
    
    func createRequest(messages: [Message], parameters: ModelParameters, model: String) -> URLRequest {
        var request = URLRequest(url: apiEndpoint.appendingPathComponent("api/generate"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert OpenAI-style messages to Ollama format
        let prompt = messages.map { "\($0.role): \($0.content)" }.joined(separator: "\n")
        
        let body: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "stream": false,
            "temperature": parameters.temperature,
            "num_predict": parameters.maxTokens,
            "top_p": parameters.topP
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        return request
    }
    
    func getAvailableModels() -> AnyPublisher<[String], APIClientError> {
        let url = apiEndpoint.appendingPathComponent("api/tags")
        
        return Future<[String], APIClientError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknownError))
                return
            }
            
            self.session.request(url)
                .validate()
                .responseJSON { response in
                    switch response.result {
                    case .success(let value):
                        let json = JSON(value)
                        let models = json["models"].arrayValue.map { $0["name"].stringValue }
                        promise(.success(models))
                        
                    case .failure(let error):
                        promise(.failure(.requestFailed(error)))
                    }
                }
        }
        .eraseToAnyPublisher()
    }
}
```

### 2. ModelConfigurationManager Implementation
1. Create the model configuration manager:

```swift
import Foundation
import Combine

class ModelConfigurationManager {
    private let userDefaults = UserDefaults.standard
    private let keychainManager: KeychainManager
    
    private let defaultTemperature: Double = 0.7
    private let defaultMaxTokens: Int = 2048
    private let defaultTopP: Double = 1.0
    private let defaultFrequencyPenalty: Double = 0.0
    private let defaultPresencePenalty: Double = 0.0
    
    private var cancellables = Set<AnyCancellable>()
    
    // OpenAI API configuration
    @Published var apiEndpoint: URL
    @Published var apiKey: String
    
    // Ollama configuration
    @Published var ollamaEnabled: Bool
    @Published var ollamaEndpoint: URL
    
    // Model parameters
    @Published var selectedModel: String
    @Published var availableModels: [String]
    @Published var temperature: Double
    @Published var maxTokens: Int
    @Published var topP: Double
    @Published var frequencyPenalty: Double
    @Published var presencePenalty: Double
    
    // API clients
    private var openAIClient: APIClient
    private var ollamaClient: OllamaAPIClient?
    
    init(keychainManager: KeychainManager) {
        self.keychainManager = keychainManager
        
        // Load or set default values
        let defaultEndpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
        self.apiEndpoint = userDefaults.url(forKey: "apiEndpoint") ?? defaultEndpoint
        self.apiKey = keychainManager.getAPIKey() ?? ""
        
        self.ollamaEnabled = userDefaults.bool(forKey: "ollamaEnabled")
        let defaultOllamaEndpoint = URL(string: "http://localhost:11434")!
        self.ollamaEndpoint = userDefaults.url(forKey: "ollamaEndpoint") ?? defaultOllamaEndpoint
        
        self.selectedModel = userDefaults.string(forKey: "selectedModel") ?? "gpt-3.5-turbo"
        self.availableModels = userDefaults.stringArray(forKey: "availableModels") ?? ["gpt-3.5-turbo", "gpt-4"]
        
        self.temperature = userDefaults.double(forKey: "temperature")
        if self.temperature == 0 { self.temperature = defaultTemperature }
        
        self.maxTokens = userDefaults.integer(forKey: "maxTokens")
        if self.maxTokens == 0 { self.maxTokens = defaultMaxTokens }
        
        self.topP = userDefaults.double(forKey: "topP")
        if self.topP == 0 { self.topP = defaultTopP }
        
        self.frequencyPenalty = userDefaults.double(forKey: "frequencyPenalty")
        if self.frequencyPenalty == 0 { self.frequencyPenalty = defaultFrequencyPenalty }
        
        self.presencePenalty = userDefaults.double(forKey: "presencePenalty")
        if self.presencePenalty == 0 { self.presencePenalty = defaultPresencePenalty }
        
        // Initialize API clients
        self.openAIClient = APIClient(endpoint: apiEndpoint, apiKey: apiKey)
        
        if ollamaEnabled {
            self.ollamaClient = OllamaAPIClient(endpoint: ollamaEndpoint)
            loadOllamaModels()
        }
        
        // Set up publishers to save changes
        setupPublishers()
    }
    
    private func setupPublishers() {
        $apiEndpoint
            .dropFirst()
            .sink { [weak self] endpoint in
                self?.userDefaults.set(endpoint, forKey: "apiEndpoint")
                self?.openAIClient.updateConfiguration(endpoint: endpoint, apiKey: self?.apiKey ?? "")
            }
            .store(in: &cancellables)
        
        $apiKey
            .dropFirst()
            .sink { [weak self] key in
                self?.keychainManager.saveAPIKey(key)
                if let endpoint = self?.apiEndpoint {
                    self?.openAIClient.updateConfiguration(endpoint: endpoint, apiKey: key)
                }
            }
            .store(in: &cancellables)
        
        $ollamaEnabled
            .dropFirst()
            .sink { [weak self] enabled in
                self?.userDefaults.set(enabled, forKey: "ollamaEnabled")
                if enabled {
                    if let endpoint = self?.ollamaEndpoint {
                        self?.ollamaClient = OllamaAPIClient(endpoint: endpoint)
                        self?.loadOllamaModels()
                    }
                } else {
                    self?.ollamaClient = nil
                }
            }
            .store(in: &cancellables)
        
        $ollamaEndpoint
            .dropFirst()
            .sink { [weak self] endpoint in
                self?.userDefaults.set(endpoint, forKey: "ollamaEndpoint")
                self?.ollamaClient?.updateEndpoint(endpoint: endpoint)
                if self?.ollamaEnabled == true {
                    self?.loadOllamaModels()
                }
            }
            .store(in: &cancellables)
        
        $selectedModel
            .dropFirst()
            .sink { [weak self] model in
                self?.userDefaults.set(model, forKey: "selectedModel")
            }
            .store(in: &cancellables)
        
        $temperature
            .dropFirst()
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: "temperature")
            }
            .store(in: &cancellables)
        
        $maxTokens
            .dropFirst()
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: "maxTokens")
            }
            .store(in: &cancellables)
        
        $topP
            .dropFirst()
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: "topP")
            }
            .store(in: &cancellables)
        
        $frequencyPenalty
            .dropFirst()
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: "frequencyPenalty")
            }
            .store(in: &cancellables)
        
        $presencePenalty
            .dropFirst()
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: "presencePenalty")
            }
            .store(in: &cancellables)
    }
    
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
    
    func sendMessage(messages: [Message]) -> AnyPublisher<String, APIClientError> {
        let parameters = getCurrentParameters()
        
        if ollamaEnabled && selectedModel.contains("ollama") {
            return ollamaClient?.sendMessage(
                messages: messages,
                parameters: parameters,
                model: selectedModel.replacingOccurrences(of: "ollama:", with: "")
            ) ?? Fail(error: APIClientError.unknownError).eraseToAnyPublisher()
        } else {
            return openAIClient.sendMessage(
                messages: messages,
                parameters: parameters,
                model: selectedModel
            )
        }
    }
    
    func streamMessage(messages: [Message]) -> AnyPublisher<String, APIClientError> {
        let parameters = getCurrentParameters()
        
        if ollamaEnabled && selectedModel.contains("ollama") {
            return ollamaClient?.streamMessage(
                messages: messages,
                parameters: parameters,
                model: selectedModel.replacingOccurrences(of: "ollama:", with: "")
            ) ?? Fail(error: APIClientError.unknownError).eraseToAnyPublisher()
        } else {
            return openAIClient.streamMessage(
                messages: messages,
                parameters: parameters,
                model: selectedModel
            )
        }
    }
    
    func testConnection(completion: @escaping (Result<Bool, APIClientError>) -> Void) {
        openAIClient.testConnection(completion: completion)
    }
    
    private func loadOllamaModels() {
        ollamaClient?.getAvailableModels()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] models in
                    guard let self = self else { return }
                    
                    let ollamaModels = models.map { "ollama:\($0)" }
                    let openAIModels = self.availableModels.filter { !$0.contains("ollama:") }
                    
                    self.availableModels = openAIModels + ollamaModels
                    self.userDefaults.set(self.availableModels, forKey: "availableModels")
                }
            )
            .store(in: &cancellables)
    }
}
```

2. Create the KeychainManager for secure API key storage:

```swift
import Foundation
import KeychainAccess

class KeychainManager {
    private let keychain: Keychain
    private let apiKeyKey = "openai_api_key"
    
    init() {
        self.keychain = Keychain(service: "com.app.macoschatapp")
            .accessibility(.whenUnlocked)
    }
    
    func saveAPIKey(_ apiKey: String) {
        do {
            try keychain.set(apiKey, key: apiKeyKey)
        } catch {
            print("Failed to save API key to Keychain: \(error)")
        }
    }
    
    func getAPIKey() -> String? {
        do {
            return try keychain.get(apiKeyKey)
        } catch {
            print("Failed to retrieve API key from Keychain: \(error)")
            return nil
        }
    }
    
    func deleteAPIKey() {
        do {
            try keychain.remove(apiKeyKey)
        } catch {
            print("Failed to delete API key from Keychain: \(error)")
        }
    }
    
    // For profile-specific API keys
    func saveAPIKey(_ apiKey: String, forProfileId profileId: String) {
        do {
            try keychain.set(apiKey, key: "api-key-\(profileId)")
        } catch {
            print("Failed to save API key for profile \(profileId) to Keychain: \(error)")
        }
    }
    
    func getAPIKey(forProfileId profileId: String) -> String? {
        do {
            return try keychain.get("api-key-\(profileId)")
        } catch {
            print("Failed to retrieve API key for profile \(profileId) from Keychain: \(error)")
            return nil
        }
    }
    
    func deleteAPIKey(forProfileId profileId: String) {
        do {
            try keychain.remove("api-key-\(profileId)")
        } catch {
            print("Failed to delete API key for profile \(profileId) from Keychain: \(error)")
        }
    }
}
```

### 3. ChatViewModel Integration with API Client
1. Update the ChatViewModel to use the API client:

```swift
import Foundation
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let modelConfigManager: ModelConfigurationManager
    private let databaseManager: DatabaseManager
    private let documentHandler: DocumentHandler
    
    private var currentConversationId: String?
    private var cancellables = Set<AnyCancellable>()
    
    init(modelConfigManager: ModelConfigurationManager, databaseManager: DatabaseManager, documentHandler: DocumentHandler) {
        self.modelConfigManager = modelConfigManager
        self.databaseManager = databaseManager
        self.documentHandler = documentHandler
        
        loadOrCreateConversation()
    }
    
    private func loadOrCreateConversation() {
        // Load the most recent conversation or create a new one
        if let conversationId = UserDefaults.standard.string(forKey: "currentConversationId"),
           let conversation = databaseManager.getConversation(id: conversationId) {
            currentConversationId = conversationId
            messages = databaseManager.getMessages(forConversationId: conversationId)
        } else {
            createNewConversation()
        }
    }
    
    func createNewConversation() {
        let conversationId = UUID().uuidString
        let title = "New Conversation"
        
        do {
            try databaseManager.createConversation(id: conversationId, title: title)
            currentConversationId = conversationId
            UserDefaults.standard.set(conversationId, forKey: "currentConversationId")
            messages = []
        } catch {
            errorMessage = "Failed to create new conversation: \(error.localizedDescription)"
        }
    }
    
    func sendMessage(content: String) {
        guard let conversationId = currentConversationId else {
            errorMessage = "No active conversation"
            return
        }
        
        // Create and save user message
        let userMessageId = UUID().uuidString
        let userMessage = Message(id: userMessageId, role: "user", content: content, timestamp: Date())
        
        do {
            try databaseManager.saveMessage(userMessage, forConversationId: conversationId)
            messages.append(userMessage)
        } catch {
            errorMessage = "Failed to save message: \(error.localizedDescription)"
            return
        }
        
        // Send to API
        isLoading = true
        errorMessage = nil
        
        modelConfigManager.streamMessage(messages: messages)
            .collect()
            .map { chunks in
                chunks.joined()
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self.handleAPIError(error)
                    }
                },
                receiveValue: { [weak self] responseContent in
                    guard let self = self, let conversationId = self.currentConversationId else { return }
                    
                    // Create and save assistant message
                    let assistantMessageId = UUID().uuidString
                    let assistantMessage = Message(
                        id: assistantMessageId,
                        role: "assistant",
                        content: responseContent,
                        timestamp: Date()
                    )
                    
                    do {
                        try self.databaseManager.saveMessage(assistantMessage, forConversationId: conversationId)
                        self.messages.append(assistantMessage)
                        
                        // Update conversation title if this is the first exchange
                        if self.messages.count == 2 {
                            let title = self.generateConversationTitle(from: content)
                            try self.databaseManager.updateConversationTitle(id: conversationId, title: title)
                        }
                    } catch {
                        self.errorMessage = "Failed to save response: \(error.localizedDescription)"
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func handleDocumentDropped(url: URL) {
        do {
            let text = try documentHandler.extractText(from: url)
            
            // Create a temporary message to show the extracted text
            let tempMessage = Message(
                id: "temp-\(UUID().uuidString)",
                role: "system",
                content: "Extracted text from \(url.lastPathComponent):\n\n\(text)",
                timestamp: Date()
            )
            
            // Show in UI but don't save to database
            messages.append(tempMessage)
            
            // In a real implementation, you would show this in an editable area
            // and let the user confirm before sending
        } catch {
            errorMessage = "Failed to extract text from document: \(error.localizedDescription)"
        }
    }
    
    private func handleAPIError(_ error: APIClientError) {
        switch error {
        case .authenticationFailed:
            errorMessage = "Authentication failed. Please check your API key."
        case .rateLimited:
            errorMessage = "Rate limit exceeded. Please try again later."
        case .serverError(let code):
            errorMessage = "Server error (\(code)). Please try again later."
        case .requestFailed(let underlyingError):
            errorMessage = "Request failed: \(underlyingError.localizedDescription)"
        default:
            errorMessage = "An unknown error occurred. Please try again."
        }
    }
    
    private func generateConversationTitle(from firstMessage: String) -> String {
        // Simple implementation - use first few words of first message
        let words = firstMessage.split(separator: " ")
        let titleWords = words.prefix(4)
        let title = titleWords.joined(separator: " ")
        return title.count > 0 ? title + "..." : "New Conversation"
    }
}
```

## Unit Tests
The following tests will verify that the API client and model configuration are implemented correctly:

### 1. APIClientTests.swift
```swift
import XCTest
import Combine
import OHHTTPStubs
import OHHTTPStubsSwift
@testable import MacOSChatApp

class APIClientTests: XCTestCase {
    
    var apiClient: APIClient!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        let endpoint = URL(string: "https://api.example.com/v1/chat/completions")!
        apiClient = APIClient(endpoint: endpoint, apiKey: "test-api-key")
        cancellables = []
    }
    
    override func tearDown() {
        HTTPStubs.removeAllStubs()
        cancellables = nil
        apiClient = nil
        super.tearDown()
    }
    
    func testCreateRequest() {
        // Given
        let messages = [
            Message(id: "1", role: "user", content: "Hello", timestamp: Date())
        ]
        let parameters = ModelParameters(
            temperature: 0.7,
            maxTokens: 100,
            topP: 1.0,
            frequencyPenalty: 0.0,
            presencePenalty: 0.0
        )
        let model = "gpt-3.5-turbo"
        
        // When
        let request = apiClient.createRequest(messages: messages, parameters: parameters, model: model)
        
        // Then
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/v1/chat/completions")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-api-key")
