#!/bin/bash

# AWS Bedrock Claude Sonnet 4 Test Script
# This script creates a curl command to test AWS Bedrock with Claude Sonnet 4

# Set variables
REGION="us-east-1"  # Bedrock is available in us-east-1
MODEL_ID="us.anthropic.claude-sonnet-4-20250514-v1:0"
ENDPOINT="https://bedrock-runtime.${REGION}.amazonaws.com/model/${MODEL_ID}/invoke"

# Create the JSON payload
PAYLOAD='{
    "anthropic_version": "bedrock-2023-05-31",
    "max_tokens": 1000,
    "messages": [
        {
            "role": "user",
            "content": "Hello! Can you confirm that you are Claude Sonnet 4 running on AWS Bedrock? Just respond with your model name and that you are working correctly."
        }
    ]
}'

echo "=== AWS Bedrock Claude Sonnet 4 Test ==="
echo "Model: $MODEL_ID"
echo "Region: $REGION"
echo "Endpoint: $ENDPOINT"
echo

# Execute the curl command with AWS signature
aws --region $REGION \
    bedrock-runtime invoke-model \
    --model-id "$MODEL_ID" \
    --body "$(echo "$PAYLOAD" | base64)" \
    --cli-binary-format raw-in-base64-out \
    /dev/stdout | jq -r '.body' | base64 -d | jq -r '.content[0].text'