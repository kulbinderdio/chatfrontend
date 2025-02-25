import XCTest
import SwiftUI
@testable import MacOSChatApp

class SettingsViewTests: XCTestCase {
    var modelConfigManager: ModelConfigurationManager!
    var keychainManager: KeychainManager!
    var userDefaultsManager: UserDefaultsManager!
    var databaseManager: DatabaseManager!
    var profileManager: ProfileManager!
    var viewModel: SettingsViewModel!
    
    override func setUp() {
        super.setUp()
        
        // Create mock dependencies
        keychainManager = KeychainManager()
        userDefaultsManager = UserDefaultsManager()
        
        modelConfigManager = ModelConfigurationManager(
            keychainManager: keychainManager,
            userDefaultsManager: userDefaultsManager
        )
        
        do {
            databaseManager = try DatabaseManager()
        } catch {
            XCTFail("Failed to initialize DatabaseManager: \(error.localizedDescription)")
            return
        }
        
        profileManager = ProfileManager(
            databaseManager: databaseManager,
            keychainManager: keychainManager
        )
        
        viewModel = SettingsViewModel(
            modelConfigManager: modelConfigManager,
            keychainManager: keychainManager,
            userDefaultsManager: userDefaultsManager,
            databaseManager: databaseManager,
            profileManager: profileManager
        )
    }
    
    override func tearDown() {
        modelConfigManager = nil
        keychainManager = nil
        userDefaultsManager = nil
        databaseManager = nil
        profileManager = nil
        viewModel = nil
        
        super.tearDown()
    }
    
    func testSettingsViewInitialization() {
        // Test that the view initializes correctly
        let view = SettingsView(
            viewModel: viewModel,
            profileManager: profileManager
        )
        
        XCTAssertNotNil(view)
    }
    
    func testSettingsViewModelInitialization() {
        // Test that the view model initializes correctly
        XCTAssertNotNil(viewModel)
    }
    
    func testGeneralSettingsView() {
        // Test the general settings view
        let view = SettingsView(
            viewModel: viewModel,
            profileManager: profileManager
        )
        
        XCTAssertNotNil(view)
    }
}
