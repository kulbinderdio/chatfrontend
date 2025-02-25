import XCTest
import SQLite
import KeychainAccess
import Alamofire
import SwiftyJSON
import Down
@testable import MacOSChatApp

class DependencyIntegrationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
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
