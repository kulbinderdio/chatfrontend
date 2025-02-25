import XCTest
import SwiftUI
@testable import MacOSChatApp

class ProjectStructureTests: XCTestCase {
    
    func testAppStructure() {
        // Test that the app structure is correct
        
        // Create dependencies
        let keychainManager = KeychainManager()
        let userDefaultsManager = UserDefaultsManager()
        let documentHandler = DocumentHandler()
        
        // Create database manager
        let databaseManager: DatabaseManager
        do {
            databaseManager = try DatabaseManager()
        } catch {
            XCTFail("Failed to initialize DatabaseManager: \(error.localizedDescription)")
            return
        }
        
        // Create profile manager
        let profileManager = ProfileManager(
            databaseManager: databaseManager,
            keychainManager: keychainManager
        )
        
        // Create model configuration manager
        let modelConfigManager = ModelConfigurationManager(
            keychainManager: keychainManager,
            userDefaultsManager: userDefaultsManager
        )
        
        // Create chat view model
        let chatViewModel = ChatViewModel(
            modelConfigManager: modelConfigManager,
            databaseManager: databaseManager,
            documentHandler: documentHandler,
            profileManager: profileManager
        )
        
        // Create settings view model
        let settingsViewModel = SettingsViewModel(
            modelConfigManager: modelConfigManager,
            keychainManager: keychainManager,
            userDefaultsManager: userDefaultsManager,
            databaseManager: databaseManager,
            profileManager: profileManager
        )
        
        // Create settings view
        let settingsView = SettingsView(
            viewModel: settingsViewModel,
            profileManager: profileManager
        )
        
        // Create chat view
        let chatView = ChatView(viewModel: chatViewModel)
        
        // Test that the views are created correctly
        XCTAssertNotNil(chatView)
        XCTAssertNotNil(settingsView)
        
        // Test app initialization
        let app = MacOSChatApp()
        XCTAssertNotNil(app)
    }
    
    func testDependencyInjection() {
        // Test that dependency injection is working correctly
        
        // Create dependencies
        let keychainManager = KeychainManager()
        let userDefaultsManager = UserDefaultsManager()
        let documentHandler = DocumentHandler()
        
        // Create database manager
        let databaseManager: DatabaseManager
        do {
            databaseManager = try DatabaseManager()
        } catch {
            XCTFail("Failed to initialize DatabaseManager: \(error.localizedDescription)")
            return
        }
        
        // Create profile manager
        let profileManager = ProfileManager(
            databaseManager: databaseManager,
            keychainManager: keychainManager
        )
        
        // Create model configuration manager
        let modelConfigManager = ModelConfigurationManager(
            keychainManager: keychainManager,
            userDefaultsManager: userDefaultsManager
        )
        
        // Create chat view model
        let chatViewModel = ChatViewModel(
            modelConfigManager: modelConfigManager,
            databaseManager: databaseManager,
            documentHandler: documentHandler,
            profileManager: profileManager
        )
        
        // Create settings view model
        let settingsViewModel = SettingsViewModel(
            modelConfigManager: modelConfigManager,
            keychainManager: keychainManager,
            userDefaultsManager: userDefaultsManager,
            databaseManager: databaseManager,
            profileManager: profileManager
        )
        
        // Test that the view models are created correctly
        XCTAssertNotNil(chatViewModel)
        XCTAssertNotNil(settingsViewModel)
    }
}
