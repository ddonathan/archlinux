#!/usr/bin/env bash
set -e

REPO_URL="https://github.com/ddonathan/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup"

# Step 1: Clone or verify dotfiles repo
if [ ! -d "$DOTFILES_DIR" ]; then
  echo "📦 Cloning dotfiles repo..."
  git clone --bare "$REPO_URL" "$DOTFILES_DIR"
else
  echo "📦 Dotfiles repo already exists."
fi

# Step 2: Define config alias for this session and rc files
alias config="git --git-dir=$DOTFILES_DIR --work-tree=$HOME"
grep -qxF "alias config=" "$HOME/.bashrc" || echo "alias config=\"git --git-dir=$DOTFILES_DIR --work-tree=$HOME\"" >> "$HOME/.bashrc"
grep -qxF "alias config=" "$HOME/.zshrc"  || echo "alias config=\"git --git-dir=$DOTFILES_DIR --work-tree=$HOME\"" >> "$HOME/.zshrc"

# Step 3: Checkout dotfiles (handling existing files)
echo "✅ Checking out dotfiles..."
config checkout 2>&1 || {
  echo "⚠️ Conflict detected, backing up existing files to $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
  config checkout 2>&1 | sed "s/.* //" | xargs -r -I{} mv "$HOME/{}" "$BACKUP_DIR/"
  config checkout
}
config config --local status.showUntrackedFiles no

# Step 4: Install packages if input lists are present
if [ -f "$HOME/pkglist.txt" ]; then
  echo "📦 Installing pacman packages..."
  sudo pacman -S --needed --noconfirm - < "$HOME/pkglist.txt"
fi

if [ -f "$HOME/yaylist.txt" ]; then
  echo "📦 Installing AUR packages with yay..."
  yay -S --needed --noconfirm - < "$HOME/yaylist.txt"
fi

if [ -f "$HOME/flatpaklist.txt" ]; then
  echo "📦 Installing Flatpak apps..."
  while IFS= read -r app; do
    flatpak install -y flathub "$app"
  done < "$HOME/flatpaklist.txt"
fi

# Step 5: Restore KDE config files
echo "🎨 Restoring KDE configuration"
KDE_FILES=(
  ".config/plasma-org.kde.plasma.desktop-appletsrc"
  ".config/kdeglobals"
  ".config/kwinrc"
  ".config/kglobalshortcutsrc"
  ".local/share/konsole"
  ".local/share/plasma"
)

for f in "${KDE_FILES[@]}"; do
  if [ -e "$HOME/$f" ]; then
    echo "✅ Found: $f"
  else
    echo "⚠️ Missing (ensure committed): $f"
  fi
done

# Step 6: Restart Plasma shell for settings to apply
echo "🔁 Restarting Plasma shell..."
kquitapp5 plasmashell && kstart plasmashell &

echo "✅ Setup complete!"
