#!/bin/sh

# Apply UMASK if defined
if [ -n "${UMASK}" ]; then
    umask "${UMASK}"
fi

# Source environment config if available
if [ -r /etc/vaultwarden.sh ]; then
    . /etc/vaultwarden.sh
elif [ -r /etc/bitwarden_rs.sh ]; then
    echo "### You are using the old /etc/bitwarden_rs.sh script, please migrate to /etc/vaultwarden.sh ###"
    . /etc/bitwarden_rs.sh
fi

# Source any extra scripts
if [ -d /etc/vaultwarden.d ]; then
    for f in /etc/vaultwarden.d/*.sh; do
        if [ -r "${f}" ]; then
            . "${f}"
        fi
    done
elif [ -d /etc/bitwarden_rs.d ]; then
    echo "### You are using the old /etc/bitwarden_rs.d script directory, please migrate to /etc/vaultwarden.d ###"
    for f in /etc/bitwarden_rs.d/*.sh; do
        if [ -r "${f}" ]; then
            . "${f}"
        fi
    done
fi

# 🔐 Inject persistent RSA keys from environment
if [ -n "$VW_RSA_KEY_B64" ] && [ -n "$VW_RSA_PUB_KEY_B64" ]; then
    mkdir -p /data

    echo "$VW_RSA_KEY_B64" | base64 -d > /data/rsa_key.pem
    echo "$VW_RSA_PUB_KEY_B64" | base64 -d > /data/rsa_key.pub.pem

    chmod 600 /data/rsa_key.pem /data/rsa_key.pub.pem
    chown 1000:1000 /data/rsa_key.pem /data/rsa_key.pub.pem
fi

# 🚀 Start Vaultwarden
exec /vaultwarden "$@"
