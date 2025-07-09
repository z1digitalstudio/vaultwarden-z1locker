# Vaultwarden S3 Configuration

This directory contains the necessary modifications and configuration files to enable Vaultwarden to work with S3-compatible storage backends like Supabase Storage, AWS S3, MinIO, and others.

## What's Changed

### Code Modifications

The main change is in `src/config.rs` where the `opendal_s3_operator_for_path` function has been enhanced to support:

- **Custom S3 endpoints** via `S3_ENDPOINT` environment variable
- **Custom credentials** via `S3_ACCESS_KEY` and `S3_SECRET_KEY` environment variables
- **Custom regions** via `S3_REGION` environment variable
- **Path-style URLs** for custom endpoints (instead of virtual host style)

### Key Features

1. **Backward Compatibility**: AWS S3 still works with the default credential chain
2. **Custom Endpoint Support**: Any S3-compatible service can be used
3. **Flexible Authentication**: Support for both AWS credential chain and custom credentials
4. **Automatic Configuration**: Detects custom endpoints and adjusts settings accordingly

## Quick Start

### For Supabase Storage

1. **Run the setup script**:

   ```bash
   ./setup_supabase.sh
   ```

2. **Follow the prompts** to enter your Supabase configuration

3. **Create the bucket** in Supabase (see generated instructions)

4. **Test the configuration**:

   ```bash
   ./test_s3_config.sh
   ```

5. **Start Vaultwarden**:
   ```bash
   docker-compose up -d
   ```

### Manual Configuration

If you prefer to configure manually:

1. **Set environment variables**:

   ```bash
   export DATA_FOLDER="s3://your-bucket/data/"
   export S3_ENDPOINT="https://your-endpoint.com"
   export S3_ACCESS_KEY="your-access-key"
   export S3_SECRET_KEY="your-secret-key"
   export S3_REGION="auto"  # or your specific region
   ```

2. **Build with S3 support**:

   ```bash
   cargo build --release --features s3
   ```

3. **Run Vaultwarden** with the environment variables

## Environment Variables

| Variable        | Required | Description        | Example                             |
| --------------- | -------- | ------------------ | ----------------------------------- |
| `DATA_FOLDER`   | Yes      | S3 bucket URL      | `s3://my-bucket/data/`              |
| `S3_ENDPOINT`   | Yes\*    | Custom S3 endpoint | `https://supabase.co/storage/v1/s3` |
| `S3_ACCESS_KEY` | Yes\*    | Access key ID      | `your-access-key`                   |
| `S3_SECRET_KEY` | Yes\*    | Secret access key  | `your-secret-key`                   |
| `S3_REGION`     | No       | S3 region          | `auto` or `us-east-1`               |

\*Required for non-AWS S3 services

## Supported Services

### Supabase Storage

```bash
DATA_FOLDER=s3://vw-data/data/
S3_ENDPOINT=https://your-project.supabase.co/storage/v1/s3
S3_ACCESS_KEY=your-anon-key
S3_SECRET_KEY=your-service-role-key
S3_REGION=auto
```

### AWS S3

```bash
DATA_FOLDER=s3://my-bucket/vaultwarden/
# No S3_ENDPOINT needed (uses AWS default)
# No S3_ACCESS_KEY/S3_SECRET_KEY needed (uses AWS credential chain)
S3_REGION=us-east-1
```

### MinIO

```bash
DATA_FOLDER=s3://vaultwarden-data/
S3_ENDPOINT=http://minio.example.com:9000
S3_ACCESS_KEY=your-minio-access-key
S3_SECRET_KEY=your-minio-secret-key
S3_REGION=us-east-1
```

### DigitalOcean Spaces

```bash
DATA_FOLDER=s3://my-space/vaultwarden/
S3_ENDPOINT=https://nyc3.digitaloceanspaces.com
S3_ACCESS_KEY=your-spaces-key
S3_SECRET_KEY=your-spaces-secret
S3_REGION=nyc3
```

## Docker Configuration

### Docker Compose Example

```yaml
version: "3.8"
services:
  vaultwarden:
    image: vaultwarden/server:latest
    environment:
      DOMAIN: "https://vw.example.com"
      DATA_FOLDER: "s3://vw-data/data/"
      S3_ENDPOINT: "https://your-project.supabase.co/storage/v1/s3"
      S3_ACCESS_KEY: "${SUPABASE_ACCESS_KEY}"
      S3_SECRET_KEY: "${SUPABASE_SECRET_KEY}"
      S3_REGION: "auto"
    ports:
      - "80:80"
```

### Docker Run Example

```bash
docker run -d \
  --name vaultwarden \
  --env DATA_FOLDER="s3://vw-data/data/" \
  --env S3_ENDPOINT="https://your-project.supabase.co/storage/v1/s3" \
  --env S3_ACCESS_KEY="your-access-key" \
  --env S3_SECRET_KEY="your-secret-key" \
  --env S3_REGION="auto" \
  --publish 80:80 \
  vaultwarden/server:latest
```

## Building with S3 Support

### Using Cargo

```bash
cargo build --release --features s3
```

### Using Docker Build

```bash
docker build --build-arg FEATURES=s3 -t vaultwarden/server:latest .
```

## Testing

### Test Configuration

```bash
./test_s3_config.sh
```

### Test with AWS CLI

```bash
aws s3 ls s3://your-bucket/ --endpoint-url https://your-endpoint.com
```

### Test with curl (Supabase)

```bash
curl -H "Authorization: Bearer your-anon-key" \
     https://your-project.supabase.co/storage/v1/object/list/bucket-name
```

## Troubleshooting

### Common Issues

1. **PermanentRedirect Error**

   - **Cause**: Vaultwarden trying to access AWS S3 instead of custom endpoint
   - **Solution**: Ensure `S3_ENDPOINT` is set correctly

2. **Authentication Errors**

   - **Cause**: Incorrect credentials
   - **Solution**: Verify `S3_ACCESS_KEY` and `S3_SECRET_KEY`

3. **Bucket Not Found**

   - **Cause**: Bucket doesn't exist or wrong name
   - **Solution**: Check bucket name in `DATA_FOLDER`

4. **Permission Errors**
   - **Cause**: Insufficient permissions
   - **Solution**: Check bucket policies and credentials

### Debug Information

Enable debug logging:

```bash
export ROCKET_LOG_LEVEL=debug
```

Check Vaultwarden logs:

```bash
docker-compose logs vaultwarden
```

## Security Considerations

1. **Credentials**: Never commit credentials to version control
2. **HTTPS**: Always use HTTPS endpoints in production
3. **IAM Policies**: Use minimal required permissions
4. **Bucket Policies**: Restrict access appropriately
5. **Environment Variables**: Use Docker secrets for sensitive data

## Migration

### From Local Storage to S3

1. Stop Vaultwarden
2. Upload data folder to S3
3. Configure S3 environment variables
4. Start Vaultwarden with new configuration

### From AWS S3 to Custom Endpoint

1. Update `S3_ENDPOINT` environment variable
2. Set `S3_ACCESS_KEY` and `S3_SECRET_KEY` if needed
3. Restart Vaultwarden

## Performance Tips

1. **Region**: Choose a region close to your Vaultwarden instance
2. **Connection Pooling**: Vaultwarden handles this automatically
3. **Caching**: Consider CDN for static assets
4. **Monitoring**: Monitor S3 request latency

## Files in This Directory

- `src/config.rs` - Modified S3 configuration code
- `S3_CONFIGURATION.md` - Detailed configuration guide
- `test_s3_config.sh` - Configuration testing script
- `setup_supabase.sh` - Supabase setup automation
- `docker-compose.supabase.yml` - Docker Compose example
- `env.supabase.example` - Environment variables example
- `README_S3.md` - This file

## Contributing

If you find issues or want to improve the S3 configuration:

1. Test with your specific S3-compatible service
2. Report any issues with detailed error messages
3. Suggest improvements for additional services
4. Update documentation for new use cases

## Support

For issues related to this S3 configuration:

1. Check the troubleshooting section above
2. Review the test script output
3. Check Vaultwarden logs for detailed error messages
4. Verify your S3 service configuration
5. Test with AWS CLI or similar tools
