# Functional Specification: MacOS AI Chat App

## 1. Overview
This document defines the functional requirements for a standalone macOS application that serves as a GUI AI chat frontend for OpenAI-compatible models. The app allows users to interact with AI models, upload PDFs and TXT files to use their text in prompts, and configure model settings—all without requiring complex server-side deployment.

## 2. Core Features

### 2.1 Chat Interface
- Native macOS UI with a clean, ChatGPT-style interface.
- Multi-turn conversation support with persistent context.
- Searchable conversation history stored locally.
- Supports switching between different OpenAI-compatible endpoints, including local models running on Ollama.

### 2.2 Document Handling
- Drag-and-drop support for PDFs and TXT files.
- Extracts and inserts full text content into the prompt (no vector database or chunking required).
- Users can manually edit the extracted text before sending the prompt.

### 2.3 Model Configuration & Settings
- **API Key Management:**
  - Secure storage of OpenAI-compatible API keys.
  - Option to enter and update API keys.
- **Model Selection:**
  - Allows users to choose from available OpenAI-compatible endpoints.
- **Adjustable Model Parameters:**
  - Temperature (default: 0.7)
  - Max Tokens (default: 2048)
  - Top-p (default: 1.0)
  - Frequency Penalty (default: 0.0)
  - Presence Penalty (default: 0.0)
- **Dark Mode Support:**
  - Follows macOS system theme.

## 3. macOS Integration
- **Menu Bar Application:**
  - Minimal UI footprint with quick access from the macOS menu bar.
  - Opens a floating chat window on click.
- **Drag and Drop Support:**
  - PDFs and TXT files can be dragged into the chat window.
- **Native macOS Look & Feel:**
  - Uses macOS system fonts, buttons, and styling for a seamless experience.
  
## 4. Data Handling & Export
- **Conversation Storage:**
  - Stores chat history locally with search functionality.
- **Copy & Export Options:**
  - Allows users to copy responses to the clipboard.
  - Export conversations as plain text or markdown files.

## 5. Technical Considerations
- **Technology Stack:**
  - Swift + SwiftUI for macOS-native UI.
  - SQLite for local chat history storage.
  - OpenAI-compatible API requests using URLSession.
- **Security Considerations:**
  - Secure storage of API keys in macOS Keychain.
  - No external cloud storage; all data remains local.

## 6. Future Enhancements (Optional)
- Voice input and text-to-speech support.
- Additional file format support (e.g., DOCX).
- Customizable UI themes.

---

This specification serves as the foundation for the application’s development. Any additional features or refinements can be iterated upon based on user feedback.

