#!/bin/bash

# Simple Slack message sender
# Usage: ./slack_send.sh <channel> <message> [thread_ts]

if [ $# -lt 2 ]; then
    echo "Usage: $0 <channel> <message> [thread_ts]"
    echo "Examples:"
    echo "  $0 '#general' 'Hello world'"
    echo "  $0 'C1234567890' 'Reply message' '1234567890.123456'"
    exit 1
fi

CHANNEL="$1"
MESSAGE="$2"
THREAD_TS="$3"

# Load environment variables from .env if it exists
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Check if SLACK_BOT_TOKEN is set
if [ -z "$SLACK_BOT_TOKEN" ]; then
    echo "Error: SLACK_BOT_TOKEN environment variable is not set"
    echo "Please set it in your .env file or export it:"
    echo "export SLACK_BOT_TOKEN=xoxb-your-token-here"
    exit 1
fi

# Build JSON payload using jq for proper escaping
if [ -n "$THREAD_TS" ]; then
    JSON_DATA=$(jq -n --arg channel "$CHANNEL" --arg text "$MESSAGE" --arg thread_ts "$THREAD_TS" \
        '{channel: $channel, text: $text, thread_ts: $thread_ts}')
else
    JSON_DATA=$(jq -n --arg channel "$CHANNEL" --arg text "$MESSAGE" \
        '{channel: $channel, text: $text}')
fi

# Send the message
curl -X POST https://slack.com/api/chat.postMessage \
  -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$JSON_DATA"