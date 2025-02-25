import XCTest
@testable import MacOSChatApp

class MenuBarComponentTests: XCTestCase {
    
    func testMenuBarManagerInitialization() throws {
        // Given
        let menuBarManager = MenuBarManager()
        
        // Then
        XCTAssertNotNil(menuBarManager)
    }
    
    func testEventMonitorInitialization() throws {
        // Given
        let eventMonitor = EventMonitor(mask: [.leftMouseDown]) { _ in }
        
        // Then
        XCTAssertNotNil(eventMonitor)
    }
}
