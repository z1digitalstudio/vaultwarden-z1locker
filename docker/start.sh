#!/bin/sh
set -e

# === Config ===
RCLONE_CONFIG_PATH="/config/rclone.conf"
RCLONE_REMOTE="vaultwarden_data"
RCLONE_BUCKET="${VAULTWARDEN_DATA_BUCKET:-vw-data}"
RCLONE_SYNC_INTERVAL="${VAULTWARDEN_DATA_SYNC_INTERVAL:-300}"

# === Build rclone config ===
mkdir -p "$(dirname "$RCLONE_CONFIG_PATH")"
cat > "$RCLONE_CONFIG_PATH" <<EOF
[$RCLONE_REMOTE]
type = s3
provider = Other
access_key_id = ${VAULTWARDEN_DATA_ACCESS_KEY}
secret_access_key = ${VAULTWARDEN_DATA_SECRET_KEY}
endpoint = ${VAULTWARDEN_DATA_ENDPOINT}
region = ${VAULTWARDEN_DATA_REGION:-us-east-1}
acl = private
EOF

# === Restore data from S3 ===
echo "⏬ Syncing from $RCLONE_REMOTE:$RCLONE_BUCKET -> /data ..."
if ! rclone sync "$RCLONE_REMOTE:$RCLONE_BUCKET" /data --config "$RCLONE_CONFIG_PATH"; then
    echo "⚠️ Restore failed — starting with empty /data"
fi

# === Optional umask ===
if [ -n "${UMASK}" ]; then
    echo "🔧 Setting umask to ${UMASK}"
    umask "${UMASK}"
fi

# === Source custom config ===
[ -r /etc/vaultwarden.sh ] && . /etc/vaultwarden.sh
[ -d /etc/vaultwarden.d ] && for f in /etc/vaultwarden.d/*.sh; do [ -r "$f" ] && . "$f"; done

# === Start Vaultwarden ===
echo "🚀 Starting Vaultwarden..."
/vaultwarden "$@" &
VW_PID=$!

# === Background sync loop ===
if [ "$VAULTWARDEN_DATA_SYNC" != "false" ]; then
    (
        while true; do
            sleep "$RCLONE_SYNC_INTERVAL"
            echo "⏫ Syncing /data -> $RCLONE_REMOTE:$RCLONE_BUCKET ..."
            if ! rclone sync /data "$RCLONE_REMOTE:$RCLONE_BUCKET" --config "$RCLONE_CONFIG_PATH"; then
                echo "⚠️ Sync failed"
            fi
        done
    ) &
fi

# === Wait for Vaultwarden to exit ===
wait $VW_PID
