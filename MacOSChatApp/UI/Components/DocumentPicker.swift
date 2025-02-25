import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct DocumentPicker: NSViewRepresentable {
    let onDocumentPicked: (URL) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if #available(macOS 12.0, *) {
            panel.allowedContentTypes = [UTType.pdf, UTType.plainText]
        } else {
            panel.allowedFileTypes = ["pdf", "txt"]
        }
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                onDocumentPicked(url)
            }
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
