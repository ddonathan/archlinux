#!/bin/bash
set -e

echo "==> Installing yay..."
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

echo "==> Installing Edge and required dependencies..."
yay -S microsoft-edge-stable-bin ca-certificates libsecret libxml2-legacy

echo "==> Installing essential tools..."
yay -S --noconfirm \
  base-devel \
  git \
  reflector \
  wget \
  curl \
  unzip \
  zsh \
  nano \
  rsync \
  dolphin \
  ark \
  ntfs-3g \
  nano \
  cups \
  hplip \
  system-config-printer \
  flatpak \
  github-desktop-bin \
  plasma-discover \
  plasma-discover-flatpak \
  flatpak \
  packagekit \
  packagekit-qt6 \
  fwupd \
  qt6-imageformats \
  appstream \
  octopi \
  libreoffice-fresh

flatpack remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo systemctl enable --now cups.service

echo "==> Updating system..."
yay -Syu

# Fix for Discover
echo "==> Installing Discover and app store support..."
sudo pacman -S --noconfirm 

echo "==> Adding Flathub remote for Flatpak..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "==> Cleaning up old Discover cache..."
rm -rf ~/.local/share/plasma-discover/
rm -rf ~/.cache/plasma-discover/

echo "✅ Discover setup complete. Reboot recommended."

echo "==> Setting up Cursor IDE..."
CURSOR_SRC="$HOME/Downloads/Cursor.AppImage"
ICON_SRC="$HOME/Downloads/cursor.png"
CURSOR_DIR="/opt/cursor"
CURSOR_BIN="$CURSOR_DIR/Cursor.AppImage"
ICON_DEST="$CURSOR_DIR/cursor.png"
DESKTOP_FILE="/usr/share/applications/cursor.desktop"

if [[ -f "$CURSOR_SRC" ]]; then
  echo "Found $CURSOR_SRC, installing..."
  sudo mkdir -p "$CURSOR_DIR"
  sudo mv "$CURSOR_SRC" "$CURSOR_BIN"
  sudo chmod +x "$CURSOR_BIN"
else
  echo "❌ Cursor.AppImage not found in $CURSOR_SRC"
  echo "   Please download it manually."
fi

if [[ -f "$ICON_SRC" ]]; then
  echo "Found $ICON_SRC, copying icon..."
  sudo mv "$ICON_SRC" "$ICON_DEST"
else
  echo "⚠️  cursor.png not found in $ICON_SRC — using generic icon."
fi

echo "Creating .desktop entry for Cursor..."
sudo tee "$DESKTOP_FILE" > /dev/null <<EOF
[Desktop Entry]
Name=Cursor
Exec=$CURSOR_BIN
Icon=${ICON_DEST:-cursor}
Type=Application
Categories=Development;IDE;
StartupNotify=true
Terminal=false
EOF

echo "✅ Cursor IDE setup complete. You may need to run \`update-desktop-database\` or reboot to see it in the app menu."

yay -Syu
