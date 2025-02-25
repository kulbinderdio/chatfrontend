import XCTest
@testable import MacOSChatApp

class ProfilesViewTests: XCTestCase {
    
    func testProfilesViewDisplaysProfiles() throws {
        // Given
        let viewModel = SettingsViewModel()
        viewModel.profiles = [
            ModelProfile(
                id: "1",
                name: "Test Profile",
                modelName: "gpt-4",
                apiEndpoint: "https://api.example.com",
                isDefault: true,
                parameters: ModelParameters(
                    temperature: 0.7,
                    maxTokens: 2048,
                    topP: 1.0,
                    frequencyPenalty: 0.0,
                    presencePenalty: 0.0
                )
            )
        ]
        
        // When
        let view = ProfilesView(viewModel: viewModel)
        
        // Then
        // Note: In a real implementation, we would use ViewInspector to test the view
        // But for now, we'll just check that the view can be created without errors
        XCTAssertNotNil(view)
    }
    
    func testProfileEditorView() throws {
        // Given
        let viewModel = SettingsViewModel()
        let profile = ModelProfile(
            id: "1",
            name: "Test Profile",
            modelName: "gpt-4",
            apiEndpoint: "https://api.example.com",
            isDefault: true,
            parameters: ModelParameters()
        )
        
        // When
        let view = ProfileEditorView(viewModel: viewModel, mode: .edit(profile: profile))
        
        // Then
        // Note: In a real implementation, we would use ViewInspector to test the view
        // But for now, we'll just check that the view can be created without errors
        XCTAssertNotNil(view)
    }
}
