#!/usr/bin/env bash
set -e

DOTFILES_DIR="$HOME/.dotfiles"
ALIAS_NAME="config"
BACKUP_NOTE=""

# Check that bare repo directory exists
if [ ! -d "$DOTFILES_DIR" ]; then
  echo "❌ No bare dotfiles repository found at $DOTFILES_DIR"
  echo "Run: git init --bare $DOTFILES_DIR"
  exit 1
fi

# Define alias for this session
alias $ALIAS_NAME="git --git-dir=$DOTFILES_DIR --work-tree=$HOME"

# Persist alias in your shell rc files
grep -qxF "alias $ALIAS_NAME=" "$HOME/.bashrc" || \
  echo "alias $ALIAS_NAME=\"git --git-dir=$DOTFILES_DIR --work-tree=$HOME\"" >> "$HOME/.bashrc"
grep -qxF "alias $ALIAS_NAME=" "$HOME/.zshrc" || \
  echo "alias $ALIAS_NAME=\"git --git-dir=$DOTFILES_DIR --work-tree=$HOME\"" >> "$HOME/.zshrc"

# Hide untracked files by default
$ALIAS_NAME config --local status.showUntrackedFiles no

echo "✅ Alias '$ALIAS_NAME' set up — use it to start tracking your dotfiles."
echo "Use commands like:"
echo "  $ALIAS_NAME add <file>"
echo "  $ALIAS_NAME commit -m \"message\""
echo "  $ALIAS_NAME status"

echo "ℹ️ No remote needed yet — you can push later if/when you want."
