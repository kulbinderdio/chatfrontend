import SwiftUI
import AppKit

struct DocumentPicker: View {
    let onDocumentPicked: (URL) -> Void
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var menuBarManager: MenuBarManager
    
    var body: some View {
        // Empty view that triggers the file picker
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear {
                openFilePicker()
            }
    }
    
    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.pdf, .plainText]
        
        // Enable security-scoped bookmarks
        panel.allowsOtherFileTypes = true
        panel.treatsFilePackagesAsDirectories = false
        panel.showsResizeIndicator = true
        panel.showsHiddenFiles = false
        panel.level = .modalPanel
        
        // Try to use the popover window from MenuBarManager
        if let popoverWindow = menuBarManager.popoverWindow {
            panel.beginSheetModal(for: popoverWindow) { response in
                if response == .OK, let url = panel.url {
                    // Create a security-scoped bookmark
                    do {
                        let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                        // Store the bookmark data if needed for long-term access
                        UserDefaults.standard.set(bookmarkData, forKey: "LastDocumentBookmark")
                    } catch {
                        print("Failed to create security-scoped bookmark: \(error)")
                    }
                    
                    onDocumentPicked(url)
                }
                // Dismiss the sheet after file selection or cancellation
                DispatchQueue.main.async {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } else if let window = NSApplication.shared.mainWindow {
            // Fallback to the application's main window
            panel.beginSheetModal(for: window) { response in
                if response == .OK, let url = panel.url {
                    // Create a security-scoped bookmark
                    do {
                        let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                        // Store the bookmark data if needed for long-term access
                        UserDefaults.standard.set(bookmarkData, forKey: "LastDocumentBookmark")
                    } catch {
                        print("Failed to create security-scoped bookmark: \(error)")
                    }
                    
                    onDocumentPicked(url)
                }
                // Dismiss the sheet after file selection or cancellation
                DispatchQueue.main.async {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } else {
            // Fallback if no window is available
            panel.begin { response in
                if response == .OK, let url = panel.url {
                    // Create a security-scoped bookmark
                    do {
                        let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                        // Store the bookmark data if needed for long-term access
                        UserDefaults.standard.set(bookmarkData, forKey: "LastDocumentBookmark")
                    } catch {
                        print("Failed to create security-scoped bookmark: \(error)")
                    }
                    
                    onDocumentPicked(url)
                }
                // Dismiss the sheet after file selection or cancellation
                DispatchQueue.main.async {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
