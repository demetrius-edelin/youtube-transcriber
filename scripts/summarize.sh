#!/bin/bash

# summarize.sh - Generate summary of transcript using OpenAI
# Usage: ./summarize.sh [FILENAME]

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config/config.sh"

# Create a new temp directory for this script
SUMM_TEMP_DIR=$(mktemp -d)

# Check if FILENAME is provided as argument or already set (when called from another script)
if [ -z "$FILENAME" ] && [ $# -eq 1 ]; then
    FILENAME="$1"
fi

# Verify that FILENAME is set
if [ -z "$FILENAME" ]; then
    echo "Error: No filename provided"
    echo "Usage: $0 FILENAME"
    echo "Example: $0 video.mp4"
    exit 1
fi

# Extract the base name without extension
BASE_NAME="${FILENAME%.*}"
TRANSCRIPT_FILE="${BASE_NAME}.txt"
SUMMARY_FILE="${BASE_NAME}_summary.txt"

echo "====================================="
echo "Generating summary with OpenAI..."
echo "====================================="

# Check if transcript file exists
if [ ! -f "$TRANSCRIPT_FILE" ]; then
    echo "Error: Transcript file $TRANSCRIPT_FILE not found"
    echo "====================================="
    echo "Process complete without summary!"
    echo "====================================="
    rm -rf "$SUMM_TEMP_DIR"
    exit 1
fi

# Verify that OPENAI_API_KEY is set
if [ -z "$OPENAI_API_KEY" ]; then
    echo "Error: OPENAI_API_KEY environment variable is not set"
    echo "Please set it with: export OPENAI_API_KEY=your_api_key"
    echo "Or add it to the config/config.sh file"
    rm -rf "$SUMM_TEMP_DIR"
    exit 1
fi

# Use OpenAI API to generate a summary
# Create the JSON request with Python to ensure proper escaping
"$PYTHON" -c "
import json
import sys

with open('$TRANSCRIPT_FILE', 'r') as f:
    transcript = f.read()

request = {
    'model': '$OPENAI_MODEL',
    'messages': [
        {
            'role': 'system',
            'content': 'You are a helpful assistant that summarizes text.'
        },
        {
            'role': 'user',
            'content': 'Summarize this text and extract the main, most important ideas touched. Please take care to not miss any important stuff. Make it short, as possible, but without leaving out essential things. Use bullet points appropriate for txt messages. Do not include any other text than the summary: ' + transcript
        }
    ],
    'temperature': 0.7,
    'max_tokens': 500
}

with open('${SUMM_TEMP_DIR}/request.json', 'w') as f:
    json.dump(request, f)
"

# Check if Python script executed correctly
if [ ! -s "${SUMM_TEMP_DIR}/request.json" ]; then
    echo "Error: Failed to create request JSON file"
    rm -rf "$SUMM_TEMP_DIR"
    exit 1
fi

curl -s https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d @"${SUMM_TEMP_DIR}/request.json" > "${SUMM_TEMP_DIR}/response.json"

# Check if jq is installed
if command -v jq >/dev/null 2>&1; then
    # Extract the summary from the response JSON using jq
    jq -r '.choices[0].message.content' "${SUMM_TEMP_DIR}/response.json" > "$SUMMARY_FILE"
else
    # Fallback if jq is not installed
    grep -o '"content":"[^"]*"' "${SUMM_TEMP_DIR}/response.json" | cut -d':' -f2- | sed 's/^"//;s/"$//' > "$SUMMARY_FILE"
fi

# Check if summary was created successfully
if [ -s "$SUMMARY_FILE" ]; then
    echo "Summary saved to: $SUMMARY_FILE"
else
    echo "Error: Failed to generate summary"
    rm -f "$SUMMARY_FILE"  # Remove empty file if failed
fi

# Clean up the temp directory
rm -rf "$SUMM_TEMP_DIR"

echo "====================================="
echo "Summary process complete!"
echo "====================================="