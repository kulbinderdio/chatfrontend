# MacOS AI Chat App

A native macOS application that serves as a GUI chat frontend for OpenAI-compatible models. The app allows users to interact with AI models, upload PDFs and TXT files to use their text in prompts, and configure model settings—all without requiring complex server-side deployment.

## Features

- Native macOS UI with a clean, ChatGPT-style interface
- Multi-turn conversation support with persistent context
- Searchable conversation history stored locally
- Support for OpenAI-compatible endpoints, including local models running on Ollama
- Drag-and-drop support for PDFs and TXT files
- Secure storage of API keys in macOS Keychain
- Customizable model parameters (temperature, max tokens, etc.)
- Dark mode support

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later (for development)
- Swift 5.9 or later (for development)

## Installation

### Option 1: Download the Release

1. Go to the [Releases](https://github.com/yourusername/MacOSChatApp/releases) page
2. Download the latest release DMG file
3. Open the DMG file and drag the app to your Applications folder

### Option 2: Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/MacOSChatApp.git
   cd MacOSChatApp
   ```

2. Build the project using Swift Package Manager:
   ```bash
   swift build -c release
   ```

3. Run the app:
   ```bash
   .build/release/MacOSChatApp
   ```

Alternatively, open the project in Xcode and build/run from there.

## Usage

### Setting Up API Keys

1. Launch the app
2. Click on the app icon in the menu bar
3. Go to Settings (or press `Cmd+,`)
4. In the API tab, enter your OpenAI API key
5. Click Save

### Starting a Conversation

1. Click on the app icon in the menu bar
2. Type your message in the text field at the bottom
3. Press Enter or click the send button

### Using Documents

1. Drag and drop a PDF or TXT file into the chat window
2. The app will extract the text from the document
3. Edit the extracted text if needed
4. Send the message

### Managing Conversations

1. Click on the sidebar button to show the conversation list
2. Select a conversation to view it
3. Use the search bar to find specific conversations
4. Click the export button to save a conversation as text or markdown

## Development

### Project Structure

- `App/`: Contains the main app entry point
- `UI/`: Contains all UI-related code
  - `Views/`: Main views of the application
  - `Components/`: Reusable UI components
  - `ViewModels/`: View models for the MVVM architecture
- `Data/`: Contains all data-related code
  - `Models/`: Data models
  - `Managers/`: Managers for various services (database, keychain, etc.)
  - `Services/`: Services for API communication, document handling, etc.
- `Utils/`: Contains utility code
  - `Extensions/`: Swift extensions
  - `Constants.swift`: App-wide constants

### Dependencies

- [SQLite.swift](https://github.com/stephencelis/SQLite.swift): SQLite database interface
- [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess): Simplified Keychain API
- [Alamofire](https://github.com/Alamofire/Alamofire): HTTP networking
- [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON): JSON parsing
- [Down](https://github.com/iwasrobbed/Down): Markdown rendering

### Testing

Run the tests using Swift Package Manager:
```bash
swift test
```

Or run the tests in Xcode.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [OpenAI](https://openai.com/) for their API
- [Ollama](https://ollama.ai/) for local model support
