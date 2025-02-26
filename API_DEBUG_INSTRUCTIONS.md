# API Debug Instructions

This document provides instructions on how to debug the API communication issues in the MacOSChatApp.

## Debug Logs

Debug logs have been added to the following files:

1. `MacOSChatApp/UI/ViewModels/ChatViewModel.swift`
2. `MacOSChatApp/Data/Services/APIClient.swift`

These logs will print detailed information about:
- The selected profile and its configuration
- The API endpoint, model name, and API key status
- The request headers and body
- The response status code, headers, and body
- The content extraction process

## Testing with the App

To test the API communication with the app:

1. Run the app
2. Go to the settings and verify that the API endpoint, model name, and API key are correct
3. Send a message in the chat interface
4. Check the console logs for detailed information about the request and response

## Testing with curl

A test script has been provided to test the API communication using curl. This can help verify if the API is working correctly outside of the app.

```bash
./test_api.sh <api_endpoint> <api_key> <model_name>
```

For example:

```bash
./test_api.sh "https://api.openai.com/v1/chat/completions" "your-api-key" "gpt-3.5-turbo"
```

Compare the curl response with the app's response to identify any differences.

## Common Issues and Solutions

1. **Invalid API Key**: Ensure that the API key is correct and has not expired.
2. **Incorrect API Endpoint**: Verify that the API endpoint is correct and accessible.
3. **Response Format Mismatch**: The app expects a specific response format. If the API returns a different format, the app may fail to extract the content.
4. **Network Issues**: Check if there are any network issues preventing the app from communicating with the API.

## Fallback Mechanism

A fallback mechanism has been added to the `APIClient.swift` file to handle unexpected response formats. If the app cannot extract content from the response using the known formats, it will attempt to use the entire response as content.

## Next Steps

1. Run the app with the debug logs enabled
2. Test the API communication using the curl script
3. Compare the results to identify the issue
4. Make the necessary changes to fix the issue
