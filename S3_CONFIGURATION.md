# Vaultwarden S3 Configuration Guide

This guide explains how to configure Vaultwarden to use S3-compatible storage backends like AWS S3, Supabase Storage, MinIO, and others.

## Overview

Vaultwarden uses Apache OpenDAL for S3 storage support, which allows it to work with any S3-compatible storage service. The S3 feature must be enabled during compilation.

## Environment Variables

### Required Variables

- `DATA_FOLDER`: Set to your S3 bucket URL in the format `s3://bucket-name/path/`
- `S3_ENDPOINT`: The S3-compatible endpoint URL (required for non-AWS S3)
- `S3_ACCESS_KEY`: Your access key ID
- `S3_SECRET_KEY`: Your secret access key
- `S3_REGION`: The region for your S3-compatible service (optional for some providers)

### Optional Variables

- `S3_BUCKET`: The bucket name (can also be specified in DATA_FOLDER)

## Configuration Examples

### Supabase Storage

```bash
# Environment variables for Supabase Storage
DATA_FOLDER=s3://vw-data/data/
S3_ENDPOINT=https://vgrulziilndwtzjewytq.supabase.co/storage/v1/s3
S3_ACCESS_KEY=your_supabase_access_key
S3_SECRET_KEY=your_supabase_secret_key
S3_REGION=auto  # Supabase doesn't require a specific region
```

### AWS S3

```bash
# Environment variables for AWS S3
DATA_FOLDER=s3://my-bucket/vaultwarden/
# No S3_ENDPOINT needed (uses AWS default)
# No S3_ACCESS_KEY/S3_SECRET_KEY needed (uses AWS credential chain)
S3_REGION=us-east-1
```

### MinIO

```bash
# Environment variables for MinIO
DATA_FOLDER=s3://vaultwarden-data/
S3_ENDPOINT=http://minio.example.com:9000
S3_ACCESS_KEY=your_minio_access_key
S3_SECRET_KEY=your_minio_secret_key
S3_REGION=us-east-1
```

## Docker Configuration

### Docker Compose Example

```yaml
version: "3.8"
services:
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    restart: unless-stopped
    environment:
      DOMAIN: "https://vw.example.com"
      DATA_FOLDER: "s3://vw-data/data/"
      S3_ENDPOINT: "https://vgrulziilndwtzjewytq.supabase.co/storage/v1/s3"
      S3_ACCESS_KEY: "your_supabase_access_key"
      S3_SECRET_KEY: "your_supabase_secret_key"
      S3_REGION: "auto"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./vw-data:/data
```

### Docker Run Example

```bash
docker run -d \
  --name vaultwarden \
  --env DOMAIN="https://vw.example.com" \
  --env DATA_FOLDER="s3://vw-data/data/" \
  --env S3_ENDPOINT="https://vgrulziilndwtzjewytq.supabase.co/storage/v1/s3" \
  --env S3_ACCESS_KEY="your_supabase_access_key" \
  --env S3_SECRET_KEY="your_supabase_secret_key" \
  --env S3_REGION="auto" \
  --restart unless-stopped \
  --publish 80:80 \
  vaultwarden/server:latest
```

## Building with S3 Support

To build Vaultwarden with S3 support, you need to enable the `s3` feature:

### Using Cargo

```bash
cargo build --release --features s3
```

### Using Docker Build

```bash
docker build --build-arg DB=sqlite --build-arg CARGO_PROFILE=release --build-arg FEATURES=s3 -t vaultwarden/server:latest .
```

## Troubleshooting

### Common Issues

1. **PermanentRedirect Error**: This occurs when Vaultwarden tries to access AWS S3 instead of your custom endpoint. Make sure you have set `S3_ENDPOINT` correctly.

2. **Authentication Errors**: Verify your `S3_ACCESS_KEY` and `S3_SECRET_KEY` are correct.

3. **Bucket Not Found**: Ensure your bucket exists and the bucket name in `DATA_FOLDER` is correct.

4. **Permission Errors**: Check that your credentials have the necessary permissions for the bucket.

### Debug Information

To get more detailed error information, you can enable debug logging:

```bash
--env ROCKET_LOG_LEVEL=debug
```

### Testing S3 Connection

You can test your S3 configuration using the AWS CLI or similar tools:

```bash
# Test with AWS CLI
aws s3 ls s3://your-bucket/ --endpoint-url https://your-endpoint.com

# Test with curl (for Supabase)
curl -H "Authorization: Bearer your_anon_key" \
     https://your-project.supabase.co/storage/v1/object/list/bucket-name
```

## Security Considerations

1. **Credentials**: Never commit credentials to version control. Use environment variables or Docker secrets.

2. **HTTPS**: Always use HTTPS endpoints for production environments.

3. **IAM Policies**: For AWS S3, use IAM policies with minimal required permissions.

4. **Bucket Policies**: Configure bucket policies to restrict access to your Vaultwarden instance.

## Migration from Local Storage

To migrate from local storage to S3:

1. Stop Vaultwarden
2. Upload your data folder to S3
3. Configure the S3 environment variables
4. Start Vaultwarden with the new configuration

## Backup Strategy

Even when using S3 storage, consider implementing a backup strategy:

1. **Cross-region replication** (for AWS S3)
2. **Versioning** on your S3 bucket
3. **Regular snapshots** of your database
4. **Export functionality** through the Vaultwarden admin interface

## Performance Considerations

1. **Region**: Choose a region close to your Vaultwarden instance for better performance
2. **Connection Pooling**: Vaultwarden automatically manages connection pooling
3. **Caching**: Consider using a CDN for static assets if needed
4. **Monitoring**: Monitor S3 request latency and adjust as needed
