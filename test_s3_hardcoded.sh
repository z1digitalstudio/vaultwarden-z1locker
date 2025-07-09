#!/bin/bash

# Vaultwarden S3 Configuration Test with Hardcoded Variables
# This script tests the S3 configuration with hardcoded values

set -e

echo "🧪 Vaultwarden S3 Configuration Test (Hardcoded)"
echo "================================================"

# Hardcoded test variables - MODIFY THESE FOR YOUR SETUP
export DATA_FOLDER="s3://vw-data/data/"
export S3_ENDPOINT="https://.supabase.co/storage/v1/s3"
export S3_ACCESS_KEY=""
export S3_SECRET_KEY=""
export S3_REGION=""

echo "📋 Using hardcoded configuration:"
echo "   DATA_FOLDER: $DATA_FOLDER"
echo "   S3_ENDPOINT: $S3_ENDPOINT"
echo "   S3_REGION: $S3_REGION"
echo "   S3_ACCESS_KEY: ${S3_ACCESS_KEY:0:8}..."
echo "   S3_SECRET_KEY: ${S3_SECRET_KEY:0:8}..."

# Extract bucket name from DATA_FOLDER
if [[ "$DATA_FOLDER" =~ s3://([^/]+) ]]; then
    BUCKET_NAME="${BASH_REMATCH[1]}"
    echo "   Bucket name: $BUCKET_NAME"
else
    echo "❌ Invalid DATA_FOLDER format. Expected: s3://bucket-name/path/"
    exit 1
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
echo "💡 To test with Vaultwarden:"
echo "   1. Build with S3 support: cargo build --release --features s3"
echo "   2. Run with these environment variables"
echo "   3. Or use Docker with the environment variables above" 