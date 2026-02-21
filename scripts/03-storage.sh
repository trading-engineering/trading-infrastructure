#!/bin/bash
set -euo pipefail

############################
# Prepare Scratch Volume
############################
echo "💾 Preparing scratch disk..."

DEVICE="/dev/oracleoci/oraclevds"
MOUNTPOINT="/mnt/scratch"

if [ ! -b "$DEVICE" ]; then
  echo "❌ Device $DEVICE not found"
  exit 1
fi

if ! sudo blkid "$DEVICE" >/dev/null 2>&1; then
  echo "📀 Formatting scratch disk..."
  sudo mkfs.ext4 "$DEVICE"
fi

sudo mkdir -p "$MOUNTPOINT"

if ! mountpoint -q "$MOUNTPOINT"; then
  sudo mount "$DEVICE" "$MOUNTPOINT"
fi

sudo mkdir -p "$MOUNTPOINT/data"
sudo chown -R 1000:1000 "$MOUNTPOINT/data"

if ! grep -q "$DEVICE" /etc/fstab; then
  echo "$DEVICE $MOUNTPOINT ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
fi

echo "✅ Scratch volume ready"
