#!/usr/bin/env python3

import json
import boto3
from botocore.exceptions import ClientError

def test_bedrock():
    """Test AWS Bedrock with Claude Sonnet 4"""
    
    # Configuration
    region = 'us-east-1'
    model_id = 'us.anthropic.claude-sonnet-4-20250514-v1:0'
    
    print("=== AWS Bedrock Claude Sonnet 4 Test ===")
    print(f"Region: {region}")
    print(f"Model: {model_id}")
    
    try:
        # Create bedrock runtime client
        client = boto3.client('bedrock-runtime', region_name=region)
        
        # Prepare the payload
        payload = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 1000,
            "messages": [
                {
                    "role": "user",
                    "content": "Hello! Please confirm you are Claude Sonnet 4 running on AWS Bedrock. Just respond with your model name and say you're working correctly."
                }
            ]
        }
        
        print(f"\nSending request to Bedrock...")
        
        # Invoke the model
        response = client.invoke_model(
            modelId=model_id,
            body=json.dumps(payload),
            contentType='application/json'
        )
        
        # Parse the response
        response_body = json.loads(response['body'].read())
        
        print("✅ Success! Response from Claude:")
        print("-" * 50)
        print(response_body['content'][0]['text'])
        print("-" * 50)
        
        return True
        
    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_message = e.response['Error']['Message']
        
        print(f"❌ AWS Error ({error_code}): {error_message}")
        
        if error_code == 'AccessDeniedException':
            print("\nPossible solutions:")
            print("1. Check if your AWS credentials have bedrock permissions")
            print("2. Verify the model is available in us-east-1 region")
            print("3. Check if Bedrock access is enabled in your AWS account")
            
    except Exception as e:
        print(f"❌ Unexpected error: {str(e)}")
        
    return False

if __name__ == "__main__":
    test_bedrock()