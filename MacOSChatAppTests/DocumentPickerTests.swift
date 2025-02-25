import XCTest
import SwiftUI
@testable import MacOSChatApp

class DocumentPickerTests: XCTestCase {
    
    func testDocumentPickerInitialization() throws {
        // Given
        let onDocumentPicked: (URL) -> Void = { _ in }
        
        // When
        let picker = DocumentPicker(onDocumentPicked: onDocumentPicked)
        
        // Then
        // Note: In a real implementation, we would use ViewInspector to test the view
        // But for now, we'll just check that the view can be created without errors
        XCTAssertNotNil(picker)
    }
}
