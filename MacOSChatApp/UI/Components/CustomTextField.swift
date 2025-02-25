import SwiftUI
import AppKit

struct CustomTextField: View {
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
    
    var body: some View {
        if isSecure {
            SecureField(placeholder, text: $text, onCommit: {
                if let onCommit = onCommit {
                    onCommit()
                }
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .disableAutocorrection(true)
        } else {
            TextField(placeholder, text: $text, onCommit: {
                if let onCommit = onCommit {
                    onCommit()
                }
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .disableAutocorrection(true)
        }
    }
}
