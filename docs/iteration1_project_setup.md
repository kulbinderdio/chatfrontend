# Iteration 1: Project Setup & Dependencies

## Overview
This iteration focuses on setting up the initial project structure, configuring the development environment, and integrating all required dependencies. This foundation will ensure that subsequent iterations can proceed smoothly.

## Objectives
- Initialize a new macOS SwiftUI project
- Configure all required dependencies
- Set up the basic project architecture
- Establish the testing framework

## Implementation Details

### 1. Project Initialization
1. Create a new macOS SwiftUI application project in Xcode
   ```bash
   # Create a new Xcode project
   # Select macOS → App
   # Product Name: MacOSChatApp
   # Organization Identifier: com.yourcompany
   # Interface: SwiftUI
   # Language: Swift
   ```

2. Configure project settings
   - Set minimum deployment target to macOS 13.0
   - Enable App Sandbox with appropriate entitlements:
     - Network access (outgoing connections)
     - User selected files (read/write access)

### 2. Dependency Management
1. Set up Swift Package Manager by adding the following dependencies to the project:

   ```swift
   // In Xcode: File → Swift Packages → Add Package Dependency
   
   // SQLite database interface
   .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.14.1"),
   
   // Simplified Keychain API
   .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
   
   // HTTP networking
   .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
   
   // JSON parsing
   .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.1"),
   
   // Markdown rendering
   .package(url: "https://github.com/iwasrobbed/Down.git", from: "0.11.0"),
   ```

2. Configure package dependencies in the target:

   ```swift
   .target(
       name: "MacOSChatApp",
       dependencies: [
           .product(name: "SQLite", package: "SQLite.swift"),
           .product(name: "KeychainAccess", package: "KeychainAccess"),
           .product(name: "Alamofire", package: "Alamofire"),
           .product(name: "SwiftyJSON", package: "SwiftyJSON"),
           .product(name: "Down", package: "Down")
       ]
   )
   ```

### 3. Project Structure Setup
1. Create the following directory structure:

   ```
   MacOSChatApp/
   ├── App/
   │   └── MacOSChatApp.swift
   ├── UI/
   │   ├── Views/
   │   │   ├── ChatView.swift
   │   │   ├── SettingsView.swift
   │   │   └── ProfilesView.swift
   │   ├── Components/
   │   │   ├── MessageBubble.swift
   │   │   ├── DocumentDropArea.swift
   │   │   └── MenuBarComponent.swift
   │   └── ViewModels/
   │       ├── ChatViewModel.swift
   │       └── SettingsViewModel.swift
   ├── Data/
   │   ├── Models/
   │   │   ├── Message.swift
   │   │   ├── Conversation.swift
   │   │   └── ModelProfile.swift
   │   ├── Managers/
   │   │   ├── DatabaseManager.swift
   │   │   ├── KeychainManager.swift
   │   │   └── UserDefaultsManager.swift
   │   └── Services/
   │       ├── APIClient.swift
   │       └── DocumentHandler.swift
   └── Utils/
       ├── Extensions/
       └── Constants.swift
   ```

2. Create placeholder files for each component with basic structure and documentation

### 4. Testing Framework Setup
1. Configure XCTest for unit testing:
   - Create a test target in the project
   - Set up test directories mirroring the main project structure

2. Set up Quick and Nimble for BDD-style testing:
   ```swift
   // Add to test target dependencies
   .package(url: "https://github.com/Quick/Quick.git", from: "7.0.0"),
   .package(url: "https://github.com/Quick/Nimble.git", from: "12.0.0"),
   ```

3. Configure OHHTTPStubs for network request stubbing:
   ```swift
   // Add to test target dependencies
   .package(url: "https://github.com/AliSoftware/OHHTTPStubs.git", from: "9.1.0"),
   ```

## Unit Tests
The following tests will verify that the project setup is complete and functional:

### 1. DependencyIntegrationTests.swift
```swift
import XCTest
import SQLite
import KeychainAccess
import Alamofire
import SwiftyJSON
import Down
@testable import MacOSChatApp

class DependencyIntegrationTests: XCTestCase {
    
    func testSQLiteIntegration() {
        // Verify SQLite can be initialized
        let db = try? Connection(.inMemory)
        XCTAssertNotNil(db, "SQLite connection should be established")
    }
    
    func testKeychainIntegration() {
        // Verify Keychain can be accessed
        let keychain = Keychain(service: "com.test.MacOSChatApp")
        XCTAssertNotNil(keychain, "Keychain should be accessible")
    }
    
    func testAlamofireIntegration() {
        // Verify Alamofire session can be created
        let session = Session()
        XCTAssertNotNil(session, "Alamofire session should be created")
    }
    
    func testSwiftyJSONIntegration() {
        // Verify SwiftyJSON can parse JSON
        let json = JSON(["test": "value"])
        XCTAssertEqual(json["test"].string, "value", "SwiftyJSON should parse correctly")
    }
    
    func testDownIntegration() {
        // Verify Down can render markdown
        let down = Down(markdownString: "# Test")
        XCTAssertNotNil(down, "Down should initialize with markdown string")
    }
}
```

### 2. ProjectStructureTests.swift
```swift
import XCTest
@testable import MacOSChatApp

class ProjectStructureTests: XCTestCase {
    
    func testAppEntryPoint() {
        // Verify app entry point exists
        let appInstance = MacOSChatApp()
        XCTAssertNotNil(appInstance, "App entry point should exist")
    }
    
    func testViewsExist() {
        // Verify core views can be instantiated
        let chatView = ChatView()
        let settingsView = SettingsView()
        
        XCTAssertNotNil(chatView, "ChatView should be instantiable")
        XCTAssertNotNil(settingsView, "SettingsView should be instantiable")
    }
    
    func testViewModelsExist() {
        // Verify core view models can be instantiated
        let chatViewModel = ChatViewModel()
        
        XCTAssertNotNil(chatViewModel, "ChatViewModel should be instantiable")
    }
    
    func testDataModelsExist() {
        // Verify data models can be instantiated
        let message = Message(id: "test", role: "user", content: "Hello", timestamp: Date())
        
        XCTAssertNotNil(message, "Message model should be instantiable")
        XCTAssertEqual(message.content, "Hello", "Message properties should be accessible")
    }
}
```

## Acceptance Criteria
- [x] Project compiles without errors
- [x] All dependencies are successfully integrated and accessible
- [x] Project structure is set up according to the specified architecture
- [x] All unit tests pass, confirming the setup is correct
- [x] Basic placeholder components are in place for future iterations

## Next Steps
Once this iteration is complete, the project will have a solid foundation with all necessary dependencies and structure in place. The next iteration will focus on implementing the core UI components.
