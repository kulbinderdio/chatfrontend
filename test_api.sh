#!/bin/bash

# This script tests the API connection using curl
# Usage: ./test_api.sh <api_endpoint> <api_key> <model_name>

# Check if all arguments are provided
if [ $# -ne 3 ]; then
    echo "Usage: ./test_api.sh <api_endpoint> <api_key> <model_name>"
    exit 1
fi

API_ENDPOINT=$1
API_KEY=$2
MODEL_NAME=$3

# For OpenRouter, the correct endpoint is https://openrouter.ai/api/v1/chat/completions
# Check if the endpoint is OpenRouter and fix it if needed
if [[ "$API_ENDPOINT" == *"openrouter.ai"* ]] && [[ "$API_ENDPOINT" != *"/chat/completions"* ]]; then
    if [[ "$API_ENDPOINT" == *"/api/v1"* ]]; then
        API_ENDPOINT="${API_ENDPOINT}/chat/completions"
        echo "Corrected OpenRouter endpoint to: $API_ENDPOINT"
    fi
fi

# Create a JSON payload for the request
JSON_PAYLOAD=$(cat <<EOF
{
    "model": "$MODEL_NAME",
    "messages": [
        {
            "role": "user",
            "content": "Hello, how are you?"
        }
    ],
    "temperature": 0.7,
    "max_tokens": 100,
    "top_p": 1.0,
    "frequency_penalty": 0.0,
    "presence_penalty": 0.0
}
EOF
)

# Print the request details
echo "Sending request to: $API_ENDPOINT"
echo "Using model: $MODEL_NAME"
echo "Request payload:"
echo "$JSON_PAYLOAD"

# Send the request using curl
echo "Response:"
curl -s -X POST "$API_ENDPOINT" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d "$JSON_PAYLOAD"

echo -e "\n\nDone."
