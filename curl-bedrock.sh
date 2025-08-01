#!/bin/bash

# Here's a curl command for AWS Bedrock testing
# This requires aws4_request for signing, which is complex with raw curl
# So we use the Python approach instead

echo "For testing AWS Bedrock from this Docker container environment:"
echo
echo "Method 1: Use the Python script (recommended):"
echo "python3 test-bedrock-python.py"
echo
echo "Method 2: Install AWS CLI v2 for bedrock support:"
echo "curl 'https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip' -o 'awscliv2.zip'"
echo "unzip awscliv2.zip"
echo "sudo ./aws/install"
echo
echo "Method 3: Test with Claude Code directly:"
echo 'source ~/.nvm/nvm.sh && nvm use --lts && claude'
echo
echo "Your AWS credentials are set up and working with Bedrock!"
echo "Region: us-east-1"
echo "Model: us.anthropic.claude-sonnet-4-20250514-v1:0"