# Iteration 4: Conversation Management & Storage

## Overview
This iteration focuses on implementing the conversation management and storage system using SQLite. This will enable the application to store chat history locally, provide search functionality, and maintain conversation context across sessions.

## Objectives
- Implement the SQLite database schema for conversations and messages
- Create the DatabaseManager for handling database operations
- Implement conversation management functionality
- Add search capabilities for conversation history
- Implement conversation export functionality
- Create unit tests for database operations

## Implementation Details

### 1. Database Schema Implementation
1. Create the SQLite database schema:

```swift
import Foundation
import SQLite

struct DatabaseSchema {
    // Conversations table
    static let conversations = Table("conversations")
    static let conversationId = Expression<String>("id")
    static let conversationTitle = Expression<String>("title")
    static let conversationCreatedAt = Expression<Date>("created_at")
    static let conversationUpdatedAt = Expression<Date>("updated_at")
    static let conversationProfileId = Expression<String?>("profile_id")
    
    // Messages table
    static let messages = Table("messages")
    static let messageId = Expression<String>("id")
    static let messageConversationId = Expression<String>("conversation_id")
    static let messageRole = Expression<String>("role")
    static let messageContent = Expression<String>("content")
    static let messageTimestamp = Expression<Date>("timestamp")
    
    // Profiles table
    static let profiles = Table("profiles")
    static let profileId = Expression<String>("id")
    static let profileName = Expression<String>("name")
    static let profileApiEndpoint = Expression<String>("api_endpoint")
    static let profileKeychainReference = Expression<String>("keychain_reference")
    static let profileModelName = Expression<String>("model_name")
    static let profileTemperature = Expression<Double>("temperature")
    static let profileMaxTokens = Expression<Int>("max_tokens")
    static let profileTopP = Expression<Double>("top_p")
    static let profileFrequencyPenalty = Expression<Double>("frequency_penalty")
    static let profilePresencePenalty = Expression<Double>("presence_penalty")
    static let profileIsDefault = Expression<Bool>("is_default")
    
    static func createTables(db: Connection) throws {
        // Create conversations table
        try db.run(conversations.create(ifNotExists: true) { table in
            table.column(conversationId, primaryKey: true)
            table.column(conversationTitle)
            table.column(conversationCreatedAt)
            table.column(conversationUpdatedAt)
            table.column(conversationProfileId)
            table.foreignKey(conversationProfileId, references: profiles, profileId, update: .cascade, delete: .setNull)
        })
        
        // Create messages table
        try db.run(messages.create(ifNotExists: true) { table in
            table.column(messageId, primaryKey: true)
            table.column(messageConversationId)
            table.column(messageRole)
            table.column(messageContent)
            table.column(messageTimestamp)
            table.foreignKey(messageConversationId, references: conversations, conversationId, update: .cascade, delete: .cascade)
        })
        
        // Create profiles table
        try db.run(profiles.create(ifNotExists: true) { table in
            table.column(profileId, primaryKey: true)
            table.column(profileName)
            table.column(profileApiEndpoint)
            table.column(profileKeychainReference)
            table.column(profileModelName)
            table.column(profileTemperature)
            table.column(profileMaxTokens)
            table.column(profileTopP)
            table.column(profileFrequencyPenalty)
            table.column(profilePresencePenalty)
            table.column(profileIsDefault)
        })
        
        // Create indexes
        try db.run(messages.createIndex(messageConversationId, ifNotExists: true))
        try db.run(conversations.createIndex(conversationUpdatedAt, ifNotExists: true))
    }
}
```

### 2. DatabaseManager Implementation
1. Create the database manager class:

```swift
import Foundation
import SQLite

enum DatabaseError: Error {
    case connectionFailed
    case queryFailed(String)
    case insertFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case notFound
}

class DatabaseManager {
    private let db: Connection
    
    init() throws {
        // Get the application support directory
        let fileManager = FileManager.default
        let appSupportDir = try fileManager.url(for: .applicationSupportDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: true)
        
        // Create app-specific directory if it doesn't exist
        let appDir = appSupportDir.appendingPathComponent("MacOSChatApp", isDirectory: true)
        if !fileManager.fileExists(atPath: appDir.path) {
            try fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        }
        
        // Open or create the database
        let dbPath = appDir.appendingPathComponent("chat_history.sqlite").path
        db = try Connection(dbPath)
        
        // Create tables if they don't exist
        try DatabaseSchema.createTables(db: db)
    }
    
    // MARK: - Conversation Methods
    
    func createConversation(id: String, title: String, profileId: String? = nil) throws {
        let insert = DatabaseSchema.conversations.insert(
            DatabaseSchema.conversationId <- id,
            DatabaseSchema.conversationTitle <- title,
            DatabaseSchema.conversationCreatedAt <- Date(),
            DatabaseSchema.conversationUpdatedAt <- Date(),
            DatabaseSchema.conversationProfileId <- profileId
        )
        
        do {
            try db.run(insert)
        } catch {
            throw DatabaseError.insertFailed("Failed to create conversation: \(error.localizedDescription)")
        }
    }
    
    func getConversation(id: String) -> Conversation? {
        let query = DatabaseSchema.conversations.filter(DatabaseSchema.conversationId == id)
        
        do {
            if let row = try db.pluck(query) {
                return Conversation(
                    id: row[DatabaseSchema.conversationId],
                    title: row[DatabaseSchema.conversationTitle],
                    createdAt: row[DatabaseSchema.conversationCreatedAt],
                    updatedAt: row[DatabaseSchema.conversationUpdatedAt],
                    profileId: row[DatabaseSchema.conversationProfileId]
                )
            }
        } catch {
            print("Error getting conversation: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    func getAllConversations(limit: Int = 50, offset: Int = 0) -> [Conversation] {
        let query = DatabaseSchema.conversations
            .order(DatabaseSchema.conversationUpdatedAt.desc)
            .limit(limit, offset: offset)
        
        var conversations: [Conversation] = []
        
        do {
            for row in try db.prepare(query) {
                let conversation = Conversation(
                    id: row[DatabaseSchema.conversationId],
                    title: row[DatabaseSchema.conversationTitle],
                    createdAt: row[DatabaseSchema.conversationCreatedAt],
                    updatedAt: row[DatabaseSchema.conversationUpdatedAt],
                    profileId: row[DatabaseSchema.conversationProfileId]
                )
                conversations.append(conversation)
            }
        } catch {
            print("Error getting all conversations: \(error.localizedDescription)")
        }
        
        return conversations
    }
    
    func updateConversationTitle(id: String, title: String) throws {
        let conversation = DatabaseSchema.conversations.filter(DatabaseSchema.conversationId == id)
        
        let update = conversation.update(
            DatabaseSchema.conversationTitle <- title,
            DatabaseSchema.conversationUpdatedAt <- Date()
        )
        
        do {
            if try db.run(update) > 0 {
                return
            } else {
                throw DatabaseError.notFound
            }
        } catch {
            throw DatabaseError.updateFailed("Failed to update conversation title: \(error.localizedDescription)")
        }
    }
    
    func updateConversationProfile(id: String, profileId: String?) throws {
        let conversation = DatabaseSchema.conversations.filter(DatabaseSchema.conversationId == id)
        
        let update = conversation.update(
            DatabaseSchema.conversationProfileId <- profileId,
            DatabaseSchema.conversationUpdatedAt <- Date()
        )
        
        do {
            if try db.run(update) > 0 {
                return
            } else {
                throw DatabaseError.notFound
            }
        } catch {
            throw DatabaseError.updateFailed("Failed to update conversation profile: \(error.localizedDescription)")
        }
    }
    
    func deleteConversation(id: String) throws {
        let conversation = DatabaseSchema.conversations.filter(DatabaseSchema.conversationId == id)
        
        do {
            if try db.run(conversation.delete()) > 0 {
                return
            } else {
                throw DatabaseError.notFound
            }
        } catch {
            throw DatabaseError.deleteFailed("Failed to delete conversation: \(error.localizedDescription)")
        }
    }
    
    func searchConversations(query: String) -> [Conversation] {
        // Create a pattern for SQLite's LIKE operator
        let pattern = "%\(query)%"
        
        // Search in conversation titles and message content
        let titleMatches = DatabaseSchema.conversations
            .filter(DatabaseSchema.conversationTitle.like(pattern))
        
        let contentMatches = DatabaseSchema.conversations
            .join(DatabaseSchema.messages, on: DatabaseSchema.conversationId == DatabaseSchema.messageConversationId)
            .filter(DatabaseSchema.messageContent.like(pattern))
            .select(distinct: DatabaseSchema.conversationId, DatabaseSchema.conversationTitle, 
                    DatabaseSchema.conversationCreatedAt, DatabaseSchema.conversationUpdatedAt, 
                    DatabaseSchema.conversationProfileId)
        
        var conversations: [Conversation] = []
        
        do {
            // Get title matches
            for row in try db.prepare(titleMatches) {
                let conversation = Conversation(
                    id: row[DatabaseSchema.conversationId],
                    title: row[DatabaseSchema.conversationTitle],
                    createdAt: row[DatabaseSchema.conversationCreatedAt],
                    updatedAt: row[DatabaseSchema.conversationUpdatedAt],
                    profileId: row[DatabaseSchema.conversationProfileId]
                )
                conversations.append(conversation)
            }
            
            // Get content matches
            for row in try db.prepare(contentMatches) {
                let conversation = Conversation(
                    id: row[DatabaseSchema.conversationId],
                    title: row[DatabaseSchema.conversationTitle],
                    createdAt: row[DatabaseSchema.conversationCreatedAt],
                    updatedAt: row[DatabaseSchema.conversationUpdatedAt],
                    profileId: row[DatabaseSchema.conversationProfileId]
                )
                
                // Only add if not already added from title matches
                if !conversations.contains(where: { $0.id == conversation.id }) {
                    conversations.append(conversation)
                }
            }
        } catch {
            print("Error searching conversations: \(error.localizedDescription)")
        }
        
        // Sort by most recently updated
        return conversations.sorted(by: { $0.updatedAt > $1.updatedAt })
    }
    
    // MARK: - Message Methods
    
    func saveMessage(_ message: Message, forConversationId conversationId: String) throws {
        let insert = DatabaseSchema.messages.insert(
            DatabaseSchema.messageId <- message.id,
            DatabaseSchema.messageConversationId <- conversationId,
            DatabaseSchema.messageRole <- message.role,
            DatabaseSchema.messageContent <- message.content,
            DatabaseSchema.messageTimestamp <- message.timestamp
        )
        
        do {
            try db.run(insert)
            
            // Update conversation's updatedAt timestamp
            let conversation = DatabaseSchema.conversations.filter(DatabaseSchema.conversationId == conversationId)
            let update = conversation.update(DatabaseSchema.conversationUpdatedAt <- Date())
            try db.run(update)
        } catch {
            throw DatabaseError.insertFailed("Failed to save message: \(error.localizedDescription)")
        }
    }
    
    func getMessages(forConversationId conversationId: String) -> [Message] {
        let query = DatabaseSchema.messages
            .filter(DatabaseSchema.messageConversationId == conversationId)
            .order(DatabaseSchema.messageTimestamp.asc)
        
        var messages: [Message] = []
        
        do {
            for row in try db.prepare(query) {
                let message = Message(
                    id: row[DatabaseSchema.messageId],
                    role: row[DatabaseSchema.messageRole],
                    content: row[DatabaseSchema.messageContent],
                    timestamp: row[DatabaseSchema.messageTimestamp]
                )
                messages.append(message)
            }
        } catch {
            print("Error getting messages: \(error.localizedDescription)")
        }
        
        return messages
    }
    
    func deleteMessage(id: String) throws {
        let message = DatabaseSchema.messages.filter(DatabaseSchema.messageId == id)
        
        do {
            if try db.run(message.delete()) > 0 {
                return
            } else {
                throw DatabaseError.notFound
            }
        } catch {
            throw DatabaseError.deleteFailed("Failed to delete message: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Profile Methods
    
    func saveProfile(_ profile: ModelProfile) throws {
        let insert = DatabaseSchema.profiles.insert(
            DatabaseSchema.profileId <- profile.id,
            DatabaseSchema.profileName <- profile.name,
            DatabaseSchema.profileApiEndpoint <- profile.apiEndpoint.absoluteString,
            DatabaseSchema.profileKeychainReference <- profile.apiKey,
            DatabaseSchema.profileModelName <- profile.modelName,
            DatabaseSchema.profileTemperature <- profile.parameters.temperature,
            DatabaseSchema.profileMaxTokens <- profile.parameters.maxTokens,
            DatabaseSchema.profileTopP <- profile.parameters.topP,
            DatabaseSchema.profileFrequencyPenalty <- profile.parameters.frequencyPenalty,
            DatabaseSchema.profilePresencePenalty <- profile.parameters.presencePenalty,
            DatabaseSchema.profileIsDefault <- profile.isDefault
        )
        
        do {
            // If this profile is set as default, unset any existing default
            if profile.isDefault {
                try unsetDefaultProfile()
            }
            
            try db.run(insert)
        } catch {
            throw DatabaseError.insertFailed("Failed to save profile: \(error.localizedDescription)")
        }
    }
    
    func updateProfile(_ profile: ModelProfile) throws {
        let profileQuery = DatabaseSchema.profiles.filter(DatabaseSchema.profileId == profile.id)
        
        let update = profileQuery.update(
            DatabaseSchema.profileName <- profile.name,
            DatabaseSchema.profileApiEndpoint <- profile.apiEndpoint.absoluteString,
            DatabaseSchema.profileKeychainReference <- profile.apiKey,
            DatabaseSchema.profileModelName <- profile.modelName,
            DatabaseSchema.profileTemperature <- profile.parameters.temperature,
            DatabaseSchema.profileMaxTokens <- profile.parameters.maxTokens,
            DatabaseSchema.profileTopP <- profile.parameters.topP,
            DatabaseSchema.profileFrequencyPenalty <- profile.parameters.frequencyPenalty,
            DatabaseSchema.profilePresencePenalty <- profile.parameters.presencePenalty,
            DatabaseSchema.profileIsDefault <- profile.isDefault
        )
        
        do {
            // If this profile is set as default, unset any existing default
            if profile.isDefault {
                try unsetDefaultProfile(exceptId: profile.id)
            }
            
            if try db.run(update) > 0 {
                return
            } else {
                throw DatabaseError.notFound
            }
        } catch {
            throw DatabaseError.updateFailed("Failed to update profile: \(error.localizedDescription)")
        }
    }
    
    func getProfile(id: String) -> ModelProfile? {
        let query = DatabaseSchema.profiles.filter(DatabaseSchema.profileId == id)
        
        do {
            if let row = try db.pluck(query) {
                let parameters = ModelParameters(
                    temperature: row[DatabaseSchema.profileTemperature],
                    maxTokens: row[DatabaseSchema.profileMaxTokens],
                    topP: row[DatabaseSchema.profileTopP],
                    frequencyPenalty: row[DatabaseSchema.profileFrequencyPenalty],
                    presencePenalty: row[DatabaseSchema.profilePresencePenalty]
                )
                
                return ModelProfile(
                    id: row[DatabaseSchema.profileId],
                    name: row[DatabaseSchema.profileName],
                    apiEndpoint: URL(string: row[DatabaseSchema.profileApiEndpoint])!,
                    apiKey: row[DatabaseSchema.profileKeychainReference],
                    modelName: row[DatabaseSchema.profileModelName],
                    parameters: parameters,
                    isDefault: row[DatabaseSchema.profileIsDefault]
                )
            }
        } catch {
            print("Error getting profile: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    func getAllProfiles() -> [ModelProfile] {
        let query = DatabaseSchema.profiles.order(DatabaseSchema.profileName.asc)
        
        var profiles: [ModelProfile] = []
        
        do {
            for row in try db.prepare(query) {
                let parameters = ModelParameters(
                    temperature: row[DatabaseSchema.profileTemperature],
                    maxTokens: row[DatabaseSchema.profileMaxTokens],
                    topP: row[DatabaseSchema.profileTopP],
                    frequencyPenalty: row[DatabaseSchema.profileFrequencyPenalty],
                    presencePenalty: row[DatabaseSchema.profilePresencePenalty]
                )
                
                let profile = ModelProfile(
                    id: row[DatabaseSchema.profileId],
                    name: row[DatabaseSchema.profileName],
                    apiEndpoint: URL(string: row[DatabaseSchema.profileApiEndpoint])!,
                    apiKey: row[DatabaseSchema.profileKeychainReference],
                    modelName: row[DatabaseSchema.profileModelName],
                    parameters: parameters,
                    isDefault: row[DatabaseSchema.profileIsDefault]
                )
                
                profiles.append(profile)
            }
        } catch {
            print("Error getting all profiles: \(error.localizedDescription)")
        }
        
        return profiles
    }
    
    func getDefaultProfile() -> ModelProfile? {
        let query = DatabaseSchema.profiles.filter(DatabaseSchema.profileIsDefault == true)
        
        do {
            if let row = try db.pluck(query) {
                let parameters = ModelParameters(
                    temperature: row[DatabaseSchema.profileTemperature],
                    maxTokens: row[DatabaseSchema.profileMaxTokens],
                    topP: row[DatabaseSchema.profileTopP],
                    frequencyPenalty: row[DatabaseSchema.profileFrequencyPenalty],
                    presencePenalty: row[DatabaseSchema.profilePresencePenalty]
                )
                
                return ModelProfile(
                    id: row[DatabaseSchema.profileId],
                    name: row[DatabaseSchema.profileName],
                    apiEndpoint: URL(string: row[DatabaseSchema.profileApiEndpoint])!,
                    apiKey: row[DatabaseSchema.profileKeychainReference],
                    modelName: row[DatabaseSchema.profileModelName],
                    parameters: parameters,
                    isDefault: row[DatabaseSchema.profileIsDefault]
                )
            }
        } catch {
            print("Error getting default profile: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    func setDefaultProfile(id: String) throws {
        // First, unset any existing default
        try unsetDefaultProfile()
        
        // Then set the new default
        let profile = DatabaseSchema.profiles.filter(DatabaseSchema.profileId == id)
        let update = profile.update(DatabaseSchema.profileIsDefault <- true)
        
        do {
            if try db.run(update) > 0 {
                return
            } else {
                throw DatabaseError.notFound
            }
        } catch {
            throw DatabaseError.updateFailed("Failed to set default profile: \(error.localizedDescription)")
        }
    }
    
    func deleteProfile(id: String) throws {
        let profile = DatabaseSchema.profiles.filter(DatabaseSchema.profileId == id)
        
        do {
            if try db.run(profile.delete()) > 0 {
                return
            } else {
                throw DatabaseError.notFound
            }
        } catch {
            throw DatabaseError.deleteFailed("Failed to delete profile: \(error.localizedDescription)")
        }
    }
    
    private func unsetDefaultProfile(exceptId: String? = nil) throws {
        var query = DatabaseSchema.profiles.filter(DatabaseSchema.profileIsDefault == true)
        
        if let exceptId = exceptId {
            query = query.filter(DatabaseSchema.profileId != exceptId)
        }
        
        let update = query.update(DatabaseSchema.profileIsDefault <- false)
        
        do {
            try db.run(update)
        } catch {
            throw DatabaseError.updateFailed("Failed to unset default profile: \(error.localizedDescription)")
        }
    }
}
```

### 3. Data Models
1. Create the Conversation model:

```swift
import Foundation

struct Conversation: Identifiable, Equatable {
    let id: String
    var title: String
    let createdAt: Date
    var updatedAt: Date
    var profileId: String?
    
    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        return lhs.id == rhs.id
    }
}
```

2. Create the Message model:

```swift
import Foundation

struct Message: Identifiable, Equatable {
    let id: String
    let role: String // "user", "assistant", or "system"
    let content: String
    let timestamp: Date
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
}
```

### 4. Conversation Export Functionality
1. Implement conversation export:

```swift
import Foundation

enum ExportFormat {
    case plainText
    case markdown
    case pdf
}

class ConversationExporter {
    private let databaseManager: DatabaseManager
    
    init(databaseManager: DatabaseManager) {
        self.databaseManager = databaseManager
    }
    
    func exportConversation(id: String, format: ExportFormat) -> URL? {
        guard let conversation = databaseManager.getConversation(id: id) else {
            return nil
        }
        
        let messages = databaseManager.getMessages(forConversationId: id)
        
        switch format {
        case .plainText:
            return exportAsPlainText(conversation: conversation, messages: messages)
        case .markdown:
            return exportAsMarkdown(conversation: conversation, messages: messages)
        case .pdf:
            return exportAsPDF(conversation: conversation, messages: messages)
        }
    }
    
    private func exportAsPlainText(conversation: Conversation, messages: [Message]) -> URL? {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let fileName = "\(conversation.title.replacingOccurrences(of: " ", with: "_")).txt"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        var content = "# \(conversation.title)\n"
        content += "Date: \(formatDate(conversation.createdAt))\n\n"
        
        for message in messages {
            content += "[\(message.role.capitalized)] \(formatDate(message.timestamp))\n"
            content += message.content
            content += "\n\n"
        }
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to export conversation as plain text: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func exportAsMarkdown(conversation: Conversation, messages: [Message]) -> URL? {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let fileName = "\(conversation.title.replacingOccurrences(of: " ", with: "_")).md"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        var content = "# \(conversation.title)\n\n"
        content += "Date: *\(formatDate(conversation.createdAt))*\n\n"
        
        for message in messages {
            content += "### \(message.role.capitalized) - \(formatDate(message.timestamp))\n\n"
            content += message.content
            content += "\n\n---\n\n"
        }
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to export conversation as markdown: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func exportAsPDF(conversation: Conversation, messages: [Message]) -> URL? {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let fileName = "\(conversation.title.replacingOccurrences(of: " ", with: "_")).pdf"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        // Create an attributed string with the conversation content
        let content = NSMutableAttributedString()
        
        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 18)
        ]
        content.append(NSAttributedString(string: "\(conversation.title)\n\n", attributes: titleAttributes))
        
        // Date
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.gray
        ]
        content.append(NSAttributedString(string: "Date: \(formatDate(conversation.createdAt))\n\n", attributes: dateAttributes))
        
        // Messages
        for message in messages {
            let roleAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 14)
            ]
            content.append(NSAttributedString(string: "\(message.role.capitalized) - \(formatDate(message.timestamp))\n", attributes: roleAttributes))
            
            let messageAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12)
            ]
            content.append(NSAttributedString(string: "\(message.content)\n\n", attributes: messageAttributes))
        }
        
        // Create PDF context
        guard let pdfData = createPDFData(from: content) else {
            return nil
        }
        
        do {
            try pdfData.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to export conversation as PDF: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func createPDFData(from attributedString: NSAttributedString) -> Data? {
        let pdfData = NSMutableData()
        
        // Create PDF context
        guard let pdfContext = CGContext(consumer: CGDataConsumer(data: pdfData as CFMutableData)!, mediaBox: nil, nil) else {
            return nil
        }
        
        // Begin PDF page
        pdfContext.beginPDFPage(nil)
        
        // Create text frame
        let frameSetter = CTFramesetterCreateWithAttributedString(attributedString)
        let pageRect = CGRect(x: 20, y: 20, width: 572, height: 752) // US Letter size (612x792) with margins
        let path = CGPath(rect: pageRect, transform: nil)
        let frame = CTFramesetterCreateFrame(frameSetter, CFRange(location: 0, length: attributedString.length), path, nil)
        
        // Draw text
        CTFrameDraw(frame, pdfContext)
        
        // End PDF page and context
        pdfContext.endPDFPage()
        pdfContext.closePDF()
        
        return pdfData as Data
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
```

### 5. ConversationListViewModel Implementation
1. Create the view model for conversation list:

```swift
import Foundation
import Combine

class ConversationListViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var searchQuery: String = ""
    
    private let databaseManager: DatabaseManager
    private let exporter: ConversationExporter
    
    private var cancellables = Set<AnyCancellable>()
    
    init(databaseManager: DatabaseManager, exporter: ConversationExporter) {
        self.databaseManager = databaseManager
        self.exporter = exporter
        
        // Set up search query publisher
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
        
        // Load initial conversations
        loadConversations()
    }
    
    func loadConversations() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let conversations = self.databaseManager.getAllConversations()
            
            DispatchQueue.main.async {
                self.conversations = conversations
                self.isLoading = false
            }
        }
    }
    
    func createNewConversation(title: String = "New Conversation") -> String? {
        let conversationId = UUID().uuidString
        
        do {
            try databaseManager.createConversation(id: conversationId, title: title)
            
            // Add to the list
            let newConversation = Conversation(
                id: conversationId,
                title: title,
                createdAt: Date(),
                updatedAt: Date(),
                profileId: nil
            )
            
            DispatchQueue.main.async {
                self.conversations.insert(newConversation, at: 0)
            }
            
            return conversationId
        } catch {
            errorMessage = "Failed to create conversation: \(error.localizedDescription)"
            return nil
        }
    }
    
    func deleteConversation(id: String) {
        do {
            try databaseManager.deleteConversation(id: id)
            
            // Remove from the list
            DispatchQueue.main.async {
                self.conversations.removeAll { $0.id == id }
            }
        } catch {
            errorMessage = "Failed to delete conversation: \(error.localizedDescription)"
        }
    }
    
    func updateConversationTitle(id: String, title: String) {
        do {
            try databaseManager.updateConversationTitle(id: id, title: title)
            
            // Update in the list
            DispatchQueue.main.async {
                if let index = self.conversations.firstIndex(
