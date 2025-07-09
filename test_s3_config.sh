#!/bin/bash

# Vaultwarden S3 Configuration Test Script
# This script helps verify your S3 configuration before running Vaultwarden

set -e

echo "🔍 Vaultwarden S3 Configuration Test"
echo "====================================="

# Check if required environment variables are set
echo "📋 Checking environment variables..."

REQUIRED_VARS=("DATA_FOLDER" "S3_ENDPOINT" "S3_ACCESS_KEY" "S3_SECRET_KEY")
MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING_VARS+=("$var")
    else
        echo "✅ $var is set"
    fi
done

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo "❌ Missing required environment variables:"
    for var in "${MISSING_VARS[@]}"; do
        echo "   - $var"
    done
    echo ""
    echo "Please set these variables and run the script again."
    exit 1
fi

echo ""
echo "🔧 Configuration details:"
echo "   DATA_FOLDER: $DATA_FOLDER"
echo "   S3_ENDPOINT: $S3_ENDPOINT"
echo "   S3_REGION: ${S3_REGION:-'not set'}"
echo "   S3_ACCESS_KEY: ${S3_ACCESS_KEY:0:8}..."

# Extract bucket name from DATA_FOLDER
if [[ "$DATA_FOLDER" =~ s3://([^/]+) ]]; then
    BUCKET_NAME="${BASH_REMATCH[1]}"
    echo "   Bucket name: $BUCKET_NAME"
else
    echo "❌ Invalid DATA_FOLDER format. Expected: s3://bucket-name/path/"
    exit 1
fi

echo ""
echo "🧪 Testing S3 connection..."

# Test S3 connection using AWS CLI if available
if command -v aws &> /dev/null; then
    echo "Using AWS CLI to test connection..."
    
    # Configure AWS CLI for custom endpoint
    export AWS_ACCESS_KEY_ID="$S3_ACCESS_KEY"
    export AWS_SECRET_ACCESS_KEY="$S3_SECRET_KEY"
    if [ -n "$S3_REGION" ]; then
        export AWS_DEFAULT_REGION="$S3_REGION"
    fi
    
    # Test bucket access
    if aws s3 ls "s3://$BUCKET_NAME/" --endpoint-url "$S3_ENDPOINT" --no-sign-request 2>/dev/null || \
       aws s3 ls "s3://$BUCKET_NAME/" --endpoint-url "$S3_ENDPOINT" 2>/dev/null; then
        echo "✅ S3 connection successful!"
        echo "✅ Bucket '$BUCKET_NAME' is accessible"
    else
        echo "❌ Failed to access bucket '$BUCKET_NAME'"
        echo "   Please check your credentials and bucket permissions"
        exit 1
    fi
else
    echo "⚠️  AWS CLI not found. Skipping connection test."
    echo "   Install AWS CLI to test S3 connectivity:"
    echo "   https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
fi

echo ""
echo "🔍 Testing endpoint accessibility..."

# Test if endpoint is reachable
if curl -s --max-time 10 "$S3_ENDPOINT" > /dev/null 2>&1; then
    echo "✅ Endpoint is reachable"
else
    echo "❌ Cannot reach endpoint: $S3_ENDPOINT"
    echo "   Please check your network connection and endpoint URL"
    exit 1
fi

echo ""
echo "📝 Vaultwarden configuration summary:"
echo "====================================="
echo "Add these environment variables to your Vaultwarden configuration:"
echo ""
echo "DATA_FOLDER=$DATA_FOLDER"
echo "S3_ENDPOINT=$S3_ENDPOINT"
echo "S3_ACCESS_KEY=$S3_ACCESS_KEY"
echo "S3_SECRET_KEY=$S3_SECRET_KEY"
if [ -n "$S3_REGION" ]; then
    echo "S3_REGION=$S3_REGION"
fi
echo ""

echo "🎉 Configuration test completed successfully!"
echo "You can now start Vaultwarden with these settings."
echo ""
echo "💡 Tips:"
echo "   - Make sure to build Vaultwarden with S3 support: --features s3"
echo "   - Use HTTPS endpoints for production environments"
echo "   - Keep your credentials secure and never commit them to version control" 