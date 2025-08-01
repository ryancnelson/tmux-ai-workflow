#!/bin/bash

# Simple test script to call Claude via AWS Bedrock using curl
# This uses the AWS CLI to sign the request for us

# Variables
REGION="us-east-1"
MODEL_ID="us.anthropic.claude-sonnet-4-20250514-v1:0"
ENDPOINT="bedrock-runtime.${REGION}.amazonaws.com"

# Create JSON payload file
cat > payload.json << 'EOF'
{
    "anthropic_version": "bedrock-2023-05-31",
    "max_tokens": 1000,
    "messages": [
        {
            "role": "user", 
            "content": "Hello! Please confirm you are Claude Sonnet 4 running on AWS Bedrock. Just respond with your model name and say you're working correctly."
        }
    ]
}
EOF

echo "=== Testing AWS Bedrock with curl ==="
echo "Region: $REGION"
echo "Model: $MODEL_ID"
echo "Payload:"
cat payload.json
echo
echo "Making request..."

# Use aws cli to make a signed request
# This is much simpler than implementing AWS v4 signatures in curl
aws --region "$REGION" bedrock-runtime invoke-model \
  --model-id "$MODEL_ID" \
  --body file://payload.json \
  response.json

if [ $? -eq 0 ] && [ -f response.json ]; then
    echo "Response received:"
    cat response.json | jq -r '.body' | base64 -d | jq -r '.content[0].text'
else
    echo "Request failed. Checking if the AWS CLI supports bedrock-runtime..."
    aws bedrock-runtime help > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "AWS CLI does not support bedrock-runtime. This requires AWS CLI v2."
        echo "Available AWS CLI version:"
        aws --version
    fi
fi

# Cleanup
rm -f payload.json response.json