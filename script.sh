#!/bin/bash

# Exit script on error
set -e

# Define variables
CRC_URL="https://developers.redhat.com/content-gateway/rest/mirror/pub/openshift-v4/clients/crc/latest/crc-linux-amd64.tar.xz"
CRC_TAR="crc-linux-amd64.tar.xz"
INSTALL_DIR="/usr/local/bin"
PULL_SECRET_FILE="$HOME/.crc-pull-secret.json"

# Ensure required dependencies are installed
for cmd in wget tar sudo; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: $cmd is not installed. Please install it and retry."
        exit 1
    fi
done

# Download CRC
echo "Downloading CRC..."
wget -q --show-progress "$CRC_URL" -O "$CRC_TAR"

# Extract the downloaded file into a temp directory
TEMP_DIR=$(mktemp -d)
tar -xf "$CRC_TAR" -C "$TEMP_DIR"

# Find extracted directory (assuming it starts with "crc-linux")
CRC_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "crc-linux-*" | head -n 1)

if [[ -z "$CRC_DIR" ]]; then
    echo "Error: Failed to locate extracted CRC directory."
    exit 1
fi

# Move CRC binary to /usr/local/bin (requires sudo if not root)
echo "Installing CRC..."
sudo mv "$CRC_DIR/crc" "$INSTALL_DIR"

# Clean up extracted files and tar
rm -rf "$CRC_TAR" "$TEMP_DIR"

# Run CRC setup
echo "Setting up CRC..."
crc setup

# Check if the pull secret file exists
if [[ ! -f "$PULL_SECRET_FILE" ]]; then
    echo "Error: Pull secret file not found at $PULL_SECRET_FILE"
    echo "Download it from https://console.redhat.com/openshift/create/local and save it as ~/.crc-pull-secret.json"
    exit 1
fi

# Start CRC with the pull secret
echo "Starting CRC with pull secret..."
crc start -p "$PULL_SECRET_FILE"

echo "✅ CRC installation and setup completed successfully!"
