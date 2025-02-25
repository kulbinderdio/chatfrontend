import Foundation

extension String {
    // Truncate string to a specified length with ellipsis
    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count > length {
            let endIndex = self.index(self.startIndex, offsetBy: length)
            return String(self[..<endIndex]) + trailing
        }
        return self
    }
    
    // Check if string is a valid URL
    var isValidURL: Bool {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return false
        }
        let matches = detector.matches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count))
        return matches.count == 1 && matches[0].range.length == self.utf16.count
    }
    
    // Check if string is a valid email
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
    
    // Convert string to Date using a specified format
    func toDate(withFormat format: String = "yyyy-MM-dd'T'HH:mm:ssZ") -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.date(from: self)
    }
    
    // Remove HTML tags from string
    var strippedHTMLTags: String {
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
    
    // Convert markdown to attributed string (placeholder for now)
    var markdownToAttributed: NSAttributedString {
        // In a real implementation, we would use a markdown parser
        // For now, just return a plain attributed string
        return NSAttributedString(string: self)
    }
}
