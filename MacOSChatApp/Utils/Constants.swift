import Foundation
import SwiftUI

// MARK: - API Constants

enum APIConstants {
    static let openAIEndpoint = "https://api.openai.com/v1/chat/completions"
    static let ollamaEndpoint = "http://localhost:11434/api/chat"
    
    static let defaultModels = [
        "gpt-3.5-turbo",
        "gpt-4",
        "gpt-4-turbo"
    ]
    
    static let ollamaModels = [
        "llama2",
        "mistral",
        "codellama"
    ]
}

// MARK: - UI Constants

enum UIConstants {
    // Colors
    static let primaryColor = Color.blue
    static let secondaryColor = Color.gray
    static let userBubbleColor = Color.blue
    static let assistantBubbleColor = Color.gray.opacity(0.3)
    
    // Sizes
    static let minWindowWidth: CGFloat = 800
    static let minWindowHeight: CGFloat = 600
    static let popoverWidth: CGFloat = 400
    static let popoverHeight: CGFloat = 600
    static let settingsWidth: CGFloat = 500
    static let settingsHeight: CGFloat = 400
    
    // Padding
    static let standardPadding: CGFloat = 16
    static let smallPadding: CGFloat = 8
    static let largePadding: CGFloat = 24
    
    // Corner radius
    static let standardCornerRadius: CGFloat = 8
    static let bubbleCornerRadius: CGFloat = 10
    
    // Fonts
    static let messageFontSize: CGFloat = 15
    static let messageLineSpacing: CGFloat = 1.3
    static let codeFontSize: CGFloat = 14
    static let timestampFontSize: CGFloat = 11
    
    // Font names
    static let primaryFontName = "SF Pro Text"
    static let alternatePrimaryFontName = "Helvetica Neue"
    static let codeFontName = "Menlo"
    static let alternateCodeFontName = "SF Mono"
}

// MARK: - Database Constants

enum DatabaseConstants {
    static let databaseName = "MacOSChatApp.sqlite"
    static let schemaVersion = 1
}

// MARK: - Notification Names

extension Notification.Name {
    static let newConversationCreated = Notification.Name("newConversationCreated")
    static let conversationDeleted = Notification.Name("conversationDeleted")
    static let conversationUpdated = Notification.Name("conversationUpdated")
    static let profileChanged = Notification.Name("profileChanged")
    static let apiKeyChanged = Notification.Name("apiKeyChanged")
}

// MARK: - Error Messages

enum ErrorMessages {
    static let apiKeyMissing = "API key is missing. Please add your API key in the settings."
    static let invalidAPIEndpoint = "Invalid API endpoint. Please check your API endpoint in the settings."
    static let networkError = "Network error. Please check your internet connection and try again."
    static let serverError = "Server error. Please try again later."
    static let documentExtractionFailed = "Failed to extract text from the document."
    static let databaseError = "Database error. Please restart the application."
}

// MARK: - Default Values

enum DefaultValues {
    static let temperature: Double = 0.7
    static let maxTokens: Int = 2048
    static let topP: Double = 1.0
    static let frequencyPenalty: Double = 0.0
    static let presencePenalty: Double = 0.0
    
    static let newConversationTitle = "New Conversation"
    static let defaultProfileName = "Default Profile"
}
