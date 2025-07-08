#!/bin/sh
set -e
echo "Restoring Vaultwarden data from remote..."
rclone copy vaultwarden_data:${VAULTWARDEN_DATA_BUCKET:-vaultwarden-backups} /data \
    --config="${RCLONE_CONFIG}" --progress
