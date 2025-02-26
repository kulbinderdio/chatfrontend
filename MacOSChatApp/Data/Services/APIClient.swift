import Foundation
import Alamofire
import SwiftyJSON
import Combine

enum APIClientError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case requestFailed(Error)
    case rateLimited
    case authenticationFailed
    case serverError(Int)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .rateLimited:
            return "Rate limit exceeded. Please try again later."
        case .authenticationFailed:
            return "Authentication failed. Please check your API key."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .unknownError:
            return "An unknown error occurred. Please try again."
        }
    }
}

class APIClient {
    private let session: Session
    private var apiEndpoint: URL
    private var apiKey: String
    private var modelName: String
    
    private var cancellables = Set<AnyCancellable>()
    
    init(apiEndpoint: String, apiKey: String, modelName: String, parameters: ModelParameters) {
        // Correct the OpenRouter endpoint if needed
        var correctedEndpoint = apiEndpoint
        if apiEndpoint.contains("openrouter.ai") && !apiEndpoint.contains("/chat/completions") {
            if apiEndpoint.contains("/api/v1") {
                correctedEndpoint = apiEndpoint + "/chat/completions"
                // Corrected OpenRouter endpoint
            }
        }
        
        guard let url = URL(string: correctedEndpoint) else {
            fatalError("Invalid API endpoint URL")
        }
        
        self.apiEndpoint = url
        self.apiKey = apiKey
        self.modelName = modelName
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 300
        
        self.session = Session(configuration: configuration)
    }
    
    // MARK: - Configuration Methods
    
    func updateConfiguration(apiEndpoint: String, apiKey: String, modelName: String, parameters: ModelParameters) {
        // Correct the OpenRouter endpoint if needed
        var correctedEndpoint = apiEndpoint
        if apiEndpoint.contains("openrouter.ai") && !apiEndpoint.contains("/chat/completions") {
            if apiEndpoint.contains("/api/v1") {
                correctedEndpoint = apiEndpoint + "/chat/completions"
            }
        }
        
        guard let url = URL(string: correctedEndpoint) else {
            // Invalid API endpoint URL
            return
        }
        
        self.apiEndpoint = url
        self.apiKey = apiKey
        self.modelName = modelName
    }
    
    // MARK: - API Methods
    
    func sendMessage(messages: [Message], parameters: ModelParameters, completion: @escaping (Result<Message, APIClientError>) -> Void) {
        let request = createRequest(messages: messages, parameters: parameters)
        
        // Request is ready to be sent
        
        session.request(request)
            .validate()
            .responseData { [weak self] response in
                guard let self = self else {
                    completion(.failure(.unknownError))
                    return
                }
                
                switch response.result {
                case .success(let data):
                    do {
                        // Check if the response is empty or not valid JSON
                        if let responseString = String(data: data, encoding: .utf8) {
                            if responseString.isEmpty || responseString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                completion(.failure(.invalidResponse))
                                return
                            }
                        }
                        
                        // Try to parse the JSON response
                        let json: JSON
                        do {
                            json = try JSON(data: data)
                        } catch {
                            // Try to create a simple JSON object from the raw response
                            if let responseString = String(data: data, encoding: .utf8) {
                                let simpleJSON: [String: Any] = ["content": responseString]
                                if let simpleData = try? JSONSerialization.data(withJSONObject: simpleJSON) {
                                    json = try JSON(data: simpleData)
                                } else {
                                    completion(.failure(.invalidResponse))
                                    return
                                }
                            } else {
                                completion(.failure(.invalidResponse))
                                return
                            }
                        }
                        
                        // Try to extract content from different possible JSON structures
                        var content: String? = nil
                        
                        // Check if this is an OpenRouter endpoint
                        let isOpenRouter = apiEndpoint.absoluteString.contains("openrouter.ai")
                        
                        if isOpenRouter {
                            // OpenRouter follows OpenAI format
                            if let openRouterContent = json["choices"][0]["message"]["content"].string {
                                content = openRouterContent
                            }
                        } else {
                            // Standard OpenAI format
                            if let openAIContent = json["choices"][0]["message"]["content"].string {
                                content = openAIContent
                            }
                            // Alternative format (some providers might use different structures)
                            else if let altContent = json["choices"][0]["text"].string {
                                content = altContent
                            }
                            // Another alternative format
                            else if let directContent = json["content"].string {
                                content = directContent
                            }
                            // Fallback for any other format
                            else if let responseContent = json["response"].string {
                                content = responseContent
                            } else {
                                // Try to extract content from any string field at the top level
                                for (_, value) in json.dictionaryValue {
                                    if let stringValue = value.string {
                                        if content == nil {
                                            content = stringValue
                                        }
                                    }
                                }
                            }
                        }
                        
                        if let extractedContent = content {
                            let responseId = UUID().uuidString
                            let responseMessage = Message(
                                id: responseId,
                                role: "assistant",
                                content: extractedContent,
                                timestamp: Date()
                            )
                            completion(.success(responseMessage))
                        } else {
                            // As a last resort, try to use the entire response as content
                            if let responseString = String(data: data, encoding: .utf8) {
                                let responseId = UUID().uuidString
                                let responseMessage = Message(
                                    id: responseId,
                                    role: "assistant",
                                    content: responseString,
                                    timestamp: Date()
                                )
                                completion(.success(responseMessage))
                            } else {
                                completion(.failure(.invalidResponse))
                            }
                        }
                    } catch {
                        completion(.failure(.invalidResponse))
                    }
                    
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
    
    func sendMessage(messages: [Message], parameters: ModelParameters) -> AnyPublisher<Message, APIClientError> {
        return Future<Message, APIClientError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknownError))
                return
            }
            
            self.sendMessage(messages: messages, parameters: parameters) { result in
                promise(result)
            }
        }
        .eraseToAnyPublisher()
    }
    
    func streamMessage(messages: [Message], parameters: ModelParameters) -> AnyPublisher<String, APIClientError> {
        let request = createStreamRequest(messages: messages, parameters: parameters)
        
        return session.streamRequest(request)
            .publishData()
            .tryMap { response -> String in
                // Process SSE data format
                let text = String(data: response.value ?? Data(), encoding: .utf8) ?? ""
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
    
    // MARK: - Request Creation
    
    func createRequest(messages: [Message], parameters: ModelParameters) -> URLRequest {
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
        
        // Check if this is an OpenRouter endpoint
        let isOpenRouter = apiEndpoint.absoluteString.contains("openrouter.ai")
        
        var body: [String: Any]
        
        if isOpenRouter {
            // OpenRouter specific format
            body = [
                "model": modelName,
                "messages": messagesJSON,
                "temperature": parameters.temperature,
                "max_tokens": parameters.maxTokens,
                "top_p": parameters.topP,
                "http_referer": "https://example.com",  // Required by OpenRouter
                "user": "user-" + UUID().uuidString     // Unique user ID
            ]
        } else {
            // Standard OpenAI format
            body = [
                "model": modelName,
                "messages": messagesJSON,
                "temperature": parameters.temperature,
                "max_tokens": parameters.maxTokens,
                "top_p": parameters.topP,
                "frequency_penalty": parameters.frequencyPenalty,
                "presence_penalty": parameters.presencePenalty
            ]
        }
        
        // Request details removed for production build
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        return request
    }
    
    func createStreamRequest(messages: [Message], parameters: ModelParameters) -> URLRequest {
        var request = createRequest(messages: messages, parameters: parameters)
        
        // Add stream parameter
        var body = try? JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any]
        body?["stream"] = true
        request.httpBody = try? JSONSerialization.data(withJSONObject: body ?? [:])
        
        return request
    }
    
    // MARK: - Testing
    
    func testConnection(completion: @escaping (Result<Bool, APIClientError>) -> Void) {
        let testMessage = [Message(id: UUID().uuidString, role: "user", content: "Hello", timestamp: Date())]
        let testParameters = ModelParameters(temperature: 0.7, maxTokens: 10, topP: 1.0, frequencyPenalty: 0.0, presencePenalty: 0.0)
        
        let request = createRequest(messages: testMessage, parameters: testParameters)
        
        session.request(request)
            .validate()
            .responseData { response in
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

// MARK: - Ollama API Client

class OllamaAPIClient {
    private let session: Session
    private var apiEndpoint: URL
    private var modelName: String
    
    private var cancellables = Set<AnyCancellable>()
    
    init(endpoint: String, modelName: String) {
        guard let url = URL(string: endpoint) else {
            fatalError("Invalid Ollama endpoint URL")
        }
        
        self.apiEndpoint = url
        self.modelName = modelName
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 300
        
        self.session = Session(configuration: configuration)
    }
    
    func updateEndpoint(endpoint: String) {
        guard let url = URL(string: endpoint) else {
            print("Invalid Ollama endpoint URL")
            return
        }
        
        self.apiEndpoint = url
    }
    
    func updateModelName(modelName: String) {
        self.modelName = modelName
    }
    
    func sendMessage(messages: [Message], parameters: ModelParameters, completion: @escaping (Result<Message, APIClientError>) -> Void) {
        let request = createRequest(messages: messages, parameters: parameters)
        
        session.request(request)
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        let json = try JSON(data: data)
                        if let content = json["response"].string {
                            let responseId = UUID().uuidString
                            let responseMessage = Message(
                                id: responseId,
                                role: "assistant",
                                content: content,
                                timestamp: Date()
                            )
                            completion(.success(responseMessage))
                        } else {
                            completion(.failure(.invalidResponse))
                        }
                    } catch {
                        completion(.failure(.invalidResponse))
                    }
                    
                case .failure(let error):
                    if let statusCode = response.response?.statusCode {
                        switch statusCode {
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
    
    func sendMessage(messages: [Message], parameters: ModelParameters) -> AnyPublisher<Message, APIClientError> {
        return Future<Message, APIClientError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknownError))
                return
            }
            
            self.sendMessage(messages: messages, parameters: parameters) { result in
                promise(result)
            }
        }
        .eraseToAnyPublisher()
    }
    
    func streamMessage(messages: [Message], parameters: ModelParameters) -> AnyPublisher<String, APIClientError> {
        let request = createRequest(messages: messages, parameters: parameters, stream: true)
        
        return session.streamRequest(request)
            .publishData()
            .tryMap { response -> String in
                let text = String(data: response.value ?? Data(), encoding: .utf8) ?? ""
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
    
    func createRequest(messages: [Message], parameters: ModelParameters, stream: Bool = false) -> URLRequest {
        var request = URLRequest(url: apiEndpoint.appendingPathComponent("api/generate"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert OpenAI-style messages to Ollama format
        let prompt = messages.map { "\($0.role): \($0.content)" }.joined(separator: "\n")
        
        let body: [String: Any] = [
            "model": modelName,
            "prompt": prompt,
            "stream": stream,
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
                .responseData { response in
                    switch response.result {
                    case .success(let data):
                        do {
                            let json = try JSON(data: data)
                            let models = json["models"].arrayValue.map { $0["name"].stringValue }
                            promise(.success(models))
                        } catch {
                            promise(.failure(.invalidResponse))
                        }
                        
                    case .failure(let error):
                        promise(.failure(.requestFailed(error)))
                    }
                }
        }
        .eraseToAnyPublisher()
    }
    
    func testConnection(completion: @escaping (Result<Bool, APIClientError>) -> Void) {
        // Try to get the list of models
        let url = apiEndpoint.appendingPathComponent("api/tags")
        
        session.request(url)
            .validate()
            .response { response in
                switch response.result {
                case .success:
                    completion(.success(true))
                case .failure(let error):
                    // If api/tags fails, try the base URL
                    self.session.request(self.apiEndpoint)
                        .validate()
                        .response { baseResponse in
                            switch baseResponse.result {
                            case .success:
                                completion(.success(true))
                            case .failure:
                                if let statusCode = response.response?.statusCode {
                                    switch statusCode {
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
    }
    
    // Helper method to check if the endpoint is reachable
    func isEndpointReachable(completion: @escaping (Bool) -> Void) {
        // Try to get the list of models
        let url = apiEndpoint.appendingPathComponent("api/tags")
        
        session.request(url)
            .validate()
            .response { response in
                switch response.result {
                case .success:
                    completion(true)
                case .failure:
                    // If api/tags fails, try the base URL
                    self.session.request(self.apiEndpoint)
                        .validate()
                        .response { baseResponse in
                            switch baseResponse.result {
                            case .success:
                                completion(true)
                            case .failure:
                                completion(false)
                            }
                        }
                }
            }
    }
}
