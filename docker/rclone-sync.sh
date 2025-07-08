#!/bin/sh
set -e
echo "Syncing Vaultwarden data to remote..."
rclone sync /data vaultwarden_data:${VAULTWARDEN_DATA_BUCKET:-vaultwarden-backups} \
    --config="${RCLONE_CONFIG}" --progress
