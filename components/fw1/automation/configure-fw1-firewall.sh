#!/bin/sh

# This script installs, enables, validates and applies nftables on FW1.

CONFIG_FILE="/etc/nftables.conf"

# Check if nftables is installed
if ! command -v nft >/dev/null 2>&1; then
    echo "nftables not found. Installing..."
    apk add nftables || exit 1
else
    echo "nftables is already installed."
fi

# Enable nftables at boot
rc-update add nftables default

# Validate configuration before applying it
if nft -c -f "$CONFIG_FILE"; then
    echo "Configuration syntax is correct."

    nft -f "$CONFIG_FILE" || exit 1
    echo "FW1 firewall rules applied successfully."
else
    echo "ERROR: Invalid nftables configuration."
    exit 1
fi

# Start nftables service if it is not running
if ! rc-service nftables status >/dev/null 2>&1; then
    rc-service nftables start
fi

echo "Current FW1 ruleset:"
nft list ruleset
