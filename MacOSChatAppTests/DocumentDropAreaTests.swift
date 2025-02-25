import XCTest
import SwiftUI
@testable import MacOSChatApp

class DocumentDropAreaTests: XCTestCase {
    
    func testDocumentDropAreaInitialization() throws {
        // Given
        let onDocumentDropped: (URL) -> Void = { _ in }
        
        // When
        let dropArea = DocumentDropArea(onDocumentDropped: onDocumentDropped) {
            Text("Test")
        }
        
        // Then
        // Note: In a real implementation, we would use ViewInspector to test the view
        // But for now, we'll just check that the view can be created without errors
        XCTAssertNotNil(dropArea)
    }
}
