# Spaces Object Storage

## Create Space

```bash
./scripts/create-space.sh my-bucket nyc3
```

## Upload Files

```bash
# Using s3cmd (S3-compatible)
s3cmd put ./file.txt s3://my-bucket/

# Using doctl
doctl compute cdn create --origin my-bucket.nyc3.digitaloceanspaces.com
```

## Configure CORS

```bash
s3cmd setcors cors.xml s3://my-bucket
```
