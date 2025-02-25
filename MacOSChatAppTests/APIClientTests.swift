import XCTest
import Combine
@testable import MacOSChatApp

class APIClientTests: XCTestCase {
    
    var apiClient: APIClient!
    var ollamaClient: OllamaAPIClient!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        let endpoint = "https://api.openai.com/v1/chat/completions"
        let apiKey = "test-api-key"
        let modelName = "gpt-3.5-turbo"
        let parameters = ModelParameters()
        
        apiClient = APIClient(apiEndpoint: endpoint, apiKey: apiKey, modelName: modelName, parameters: parameters)
        ollamaClient = OllamaAPIClient(endpoint: "http://localhost:11434", modelName: "llama2")
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        apiClient = nil
        ollamaClient = nil
        super.tearDown()
    }
    
    // MARK: - OpenAI API Client Tests
    
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
        
        // When
        let request = apiClient.createRequest(messages: messages, parameters: parameters)
        
        // Then
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://api.openai.com/v1/chat/completions")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-api-key")
        
        // Verify request body
        guard let httpBody = request.httpBody else {
            XCTFail("HTTP body should not be nil")
            return
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: httpBody, options: []) as? [String: Any]
            XCTAssertNotNil(json)
            XCTAssertEqual(json?["model"] as? String, "gpt-3.5-turbo")
            XCTAssertEqual(json?["temperature"] as? Double, 0.7)
            XCTAssertEqual(json?["max_tokens"] as? Int, 100)
            XCTAssertEqual(json?["top_p"] as? Double, 1.0)
            XCTAssertEqual(json?["frequency_penalty"] as? Double, 0.0)
            XCTAssertEqual(json?["presence_penalty"] as? Double, 0.0)
            
            let messagesJson = json?["messages"] as? [[String: String]]
            XCTAssertNotNil(messagesJson)
            XCTAssertEqual(messagesJson?.count, 1)
            XCTAssertEqual(messagesJson?[0]["role"], "user")
            XCTAssertEqual(messagesJson?[0]["content"], "Hello")
        } catch {
            XCTFail("Failed to parse HTTP body: \(error)")
        }
    }
    
    func testCreateStreamRequest() {
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
        
        // When
        let request = apiClient.createStreamRequest(messages: messages, parameters: parameters)
        
        // Then
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://api.openai.com/v1/chat/completions")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-api-key")
        
        // Verify request body
        guard let httpBody = request.httpBody else {
            XCTFail("HTTP body should not be nil")
            return
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: httpBody, options: []) as? [String: Any]
            XCTAssertNotNil(json)
            XCTAssertEqual(json?["model"] as? String, "gpt-3.5-turbo")
            XCTAssertEqual(json?["stream"] as? Bool, true)
        } catch {
            XCTFail("Failed to parse HTTP body: \(error)")
        }
    }
    
    func testUpdateConfiguration() {
        // Given
        let newEndpoint = "https://api.example.com/v1/chat/completions"
        let newApiKey = "new-test-api-key"
        let newModelName = "gpt-4"
        let newParameters = ModelParameters(
            temperature: 0.5,
            maxTokens: 200,
            topP: 0.9,
            frequencyPenalty: 0.1,
            presencePenalty: 0.1
        )
        
        // When
        apiClient.updateConfiguration(apiEndpoint: newEndpoint, apiKey: newApiKey, modelName: newModelName, parameters: newParameters)
        
        // Then
        let messages = [
            Message(id: "1", role: "user", content: "Hello", timestamp: Date())
        ]
        let request = apiClient.createRequest(messages: messages, parameters: newParameters)
        
        XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/v1/chat/completions")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer new-test-api-key")
        
        guard let httpBody = request.httpBody else {
            XCTFail("HTTP body should not be nil")
            return
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: httpBody, options: []) as? [String: Any]
            XCTAssertNotNil(json)
            XCTAssertEqual(json?["model"] as? String, "gpt-4")
        } catch {
            XCTFail("Failed to parse HTTP body: \(error)")
        }
    }
    
    // MARK: - Ollama API Client Tests
    
    func testOllamaCreateRequest() {
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
        
        // When
        let request = ollamaClient.createRequest(messages: messages, parameters: parameters)
        
        // Then
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "http://localhost:11434/api/generate")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        
        // Verify request body
        guard let httpBody = request.httpBody else {
            XCTFail("HTTP body should not be nil")
            return
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: httpBody, options: []) as? [String: Any]
            XCTAssertNotNil(json)
            XCTAssertEqual(json?["model"] as? String, "llama2")
            XCTAssertEqual(json?["temperature"] as? Double, 0.7)
            XCTAssertEqual(json?["num_predict"] as? Int, 100)
            XCTAssertEqual(json?["top_p"] as? Double, 1.0)
            XCTAssertEqual(json?["stream"] as? Bool, false)
            
            let prompt = json?["prompt"] as? String
            XCTAssertNotNil(prompt)
            XCTAssertEqual(prompt, "user: Hello")
        } catch {
            XCTFail("Failed to parse HTTP body: \(error)")
        }
    }
    
    func testOllamaCreateStreamRequest() {
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
        
        // When
        let request = ollamaClient.createRequest(messages: messages, parameters: parameters, stream: true)
        
        // Then
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "http://localhost:11434/api/generate")
        
        // Verify request body
        guard let httpBody = request.httpBody else {
            XCTFail("HTTP body should not be nil")
            return
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: httpBody, options: []) as? [String: Any]
            XCTAssertNotNil(json)
            XCTAssertEqual(json?["stream"] as? Bool, true)
        } catch {
            XCTFail("Failed to parse HTTP body: \(error)")
        }
    }
    
    func testOllamaUpdateEndpoint() {
        // Given
        let newEndpoint = "http://example.com:11434"
        
        // When
        ollamaClient.updateEndpoint(endpoint: newEndpoint)
        
        // Then
        let messages = [
            Message(id: "1", role: "user", content: "Hello", timestamp: Date())
        ]
        let parameters = ModelParameters()
        let request = ollamaClient.createRequest(messages: messages, parameters: parameters)
        
        XCTAssertEqual(request.url?.absoluteString, "http://example.com:11434/api/generate")
    }
    
    func testOllamaUpdateModelName() {
        // Given
        let newModelName = "mistral"
        
        // When
        ollamaClient.updateModelName(modelName: newModelName)
        
        // Then
        let messages = [
            Message(id: "1", role: "user", content: "Hello", timestamp: Date())
        ]
        let parameters = ModelParameters()
        let request = ollamaClient.createRequest(messages: messages, parameters: parameters)
        
        guard let httpBody = request.httpBody else {
            XCTFail("HTTP body should not be nil")
            return
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: httpBody, options: []) as? [String: Any]
            XCTAssertNotNil(json)
            XCTAssertEqual(json?["model"] as? String, "mistral")
        } catch {
            XCTFail("Failed to parse HTTP body: \(error)")
        }
    }
}
