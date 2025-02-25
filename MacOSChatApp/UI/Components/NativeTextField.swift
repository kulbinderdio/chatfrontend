import SwiftUI
import AppKit

struct NativeTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var isSecure: Bool
    var onCommit: (() -> Void)?
    
    init(text: Binding<String>, placeholder: String, isSecure: Bool = false, onCommit: (() -> Void)? = nil) {
        self._text = text
        self.placeholder = placeholder
        self.isSecure = isSecure
        self.onCommit = onCommit
    }
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = isSecure ? NSSecureTextField() : NSTextField()
        textField.placeholderString = placeholder
        textField.stringValue = text
        textField.delegate = context.coordinator
        textField.bezelStyle = .roundedBezel
        textField.isBordered = true
        textField.isEditable = true
        textField.isSelectable = true
        textField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        textField.focusRingType = .exterior
        
        // Make sure the text field can receive focus
        textField.refusesFirstResponder = false
        
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: NativeTextField
        
        init(_ parent: NativeTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            DispatchQueue.main.async {
                self.parent.text = textField.stringValue
            }
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            if let onCommit = parent.onCommit {
                onCommit()
            }
        }
    }
}
