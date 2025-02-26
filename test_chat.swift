import Foundation

// Simple test script to verify API client functionality

// Define the Message struct
struct Message: Codable {
    let role: String
    let content: String
}

// Define the request payload
struct ChatRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let max_tokens: Int
    let top_p: Double
    let frequency_penalty: Double
    let presence_penalty: Double
}

// Define the response structure
struct ChatResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let choices: [Choice]
    let usage: Usage
    
    struct Choice: Codable {
        let index: Int
        let message: Message
        let finish_reason: String
    }
    
    struct Usage: Codable {
        let prompt_tokens: Int
        let completion_tokens: Int
        let total_tokens: Int
    }
}

// Function to send a chat request
func sendChatRequest(apiKey: String, endpoint: String, model: String, messages: [Message], completion: @escaping (Result<ChatResponse, Error>) -> Void) {
    // Correct the OpenRouter endpoint if needed
    var correctedEndpoint = endpoint
    if endpoint.contains("openrouter.ai") && !endpoint.contains("/chat/completions") {
        if endpoint.contains("/api/v1") {
            correctedEndpoint = endpoint + "/chat/completions"
            print("Corrected OpenRouter endpoint to: \(correctedEndpoint)")
        }
    }
    
    // Create the URL
    guard let url = URL(string: correctedEndpoint) else {
        completion(.failure(NSError(domain: "InvalidURL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
        return
    }
    
    // Create the request
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    
    // Create the request payload
    let payload = ChatRequest(
        model: model,
        messages: messages,
        temperature: 0.7,
        max_tokens: 100,
        top_p: 1.0,
        frequency_penalty: 0.0,
        presence_penalty: 0.0
    )
    
    // Encode the payload
    do {
        let encoder = JSONEncoder()
        let data = try encoder.encode(payload)
        request.httpBody = data
        
        // Print the request payload
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Request payload:")
            print(jsonString)
        }
    } catch {
        completion(.failure(error))
        return
    }
    
    // Send the request
    print("Sending request to: \(url.absoluteString)")
    print("Using model: \(model)")
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let data = data else {
            completion(.failure(NSError(domain: "NoData", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
            return
        }
        
        // Print the raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw response:")
            print(responseString)
        }
        
        // Parse the response
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(ChatResponse.self, from: data)
            completion(.success(response))
        } catch {
            print("Error decoding response: \(error)")
            completion(.failure(error))
        }
    }
    
    task.resume()
}

// Main function
func main() {
    // Get command line arguments
    let arguments = CommandLine.arguments
    
    if arguments.count < 4 {
        print("Usage: swift test_chat.swift <endpoint> <api_key> <model>")
        exit(1)
    }
    
    let endpoint = arguments[1]
    let apiKey = arguments[2]
    let model = arguments[3]
    
    // Create a message
    let messages = [
        Message(role: "user", content: "Hello how are you?")
    ]
    
    // Send the request
    sendChatRequest(apiKey: apiKey, endpoint: endpoint, model: model, messages: messages) { result in
        switch result {
        case .success(let response):
            print("\nSuccessfully received response:")
            print("ID: \(response.id)")
            print("Model: \(model)")
            print("Content: \(response.choices[0].message.content)")
            print("Tokens used: \(response.usage.total_tokens)")
        case .failure(let error):
            print("\nError: \(error.localizedDescription)")
        }
        
        exit(0)
    }
    
    // Keep the program running until the request completes
    RunLoop.main.run()
}

// Run the main function
main()
