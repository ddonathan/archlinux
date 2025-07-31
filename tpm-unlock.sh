#!/usr/bin/env bash
set -euxo pipefail
exec > >(tee "tpm2-setup-$(date +%F_%H-%M-%S).log") 2>&1

LUKS_DEV="/dev/nvme0n1p2"         # Adjust accordingly
BACKUP_DIR="/mnt/usb"            # Directory to store LUKS header backup
PCRS="7"                         # Only PCR 7 for stable auto-unlock

echo "=== TPM2 Auto-Unlock Setup (PCR 7-binding only) ==="

# Ensure the device exists
if ! [ -b "$LUKS_DEV" ]; then
  echo "ERROR: Device $LUKS_DEV not found!"
  exit 1
fi

echo "--- Verifying LUKS2 format..."
if ! sudo cryptsetup luksDump "$LUKS_DEV" | grep -q "Version:[[:space:]]*2"; then
  echo "ERROR: Device is not LUKS2. Please convert first."
  exit 1
fi

echo "--- Enrolling TPM2 key (bound to PCR 7)..."
sudo systemd-cryptenroll --wipe-slot=tpm2 \
  --tpm2-device=auto \
  --tpm2-pcrs="$PCRS" \
  "$LUKS_DEV"

echo "--- Adding backup passphrase slot..."
sudo cryptsetup luksAddKey "$LUKS_DEV"

echo "--- Backing up LUKS header..."
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/luks-header-$(date +%F_%H-%M-%S).img"
sudo cryptsetup luksHeaderBackup "$LUKS_DEV" --header-backup-file "$BACKUP_FILE"
echo "→ Backup saved: $BACKUP_FILE"

echo "--- Updating /etc/crypttab if needed..."
UUID=$(blkid -s UUID -o value "$LUKS_DEV")
LINE="root UUID=$UUID none luks,tpm2-device=auto"
if ! grep -q "$UUID" /etc/crypttab 2>/dev/null; then
  echo "$LINE" | sudo tee -a /etc/crypttab
  echo "→ crypttab updated"
else
  echo "→ crypttab entry already exists"
fi

echo "--- Rebuilding initramfs..."
sudo mkinitcpio -P

echo "✔️ TPM auto-unlock setup complete. Reboot to test."
