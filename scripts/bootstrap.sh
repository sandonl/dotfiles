#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Bootstrap Script for Sandon's Development Environment
# =============================================================================
# Run this on a fresh Linux VM after cloning the dotfiles repo.
# Usage: ./scripts/bootstrap.sh
# =============================================================================

if [[ "$OSTYPE" != "linux-gnu"* ]]; then
  echo "This script is for Linux only. Use darwin-rebuild on macOS."
  exit 1
fi

echo "Bootstrapping development environment..."

# -----------------------------------------------------------------------------
# System packages (installed via apt for PATH availability)
# -----------------------------------------------------------------------------
echo "Installing system packages..."
sudo apt-get update -qq
sudo apt-get install -y -qq mosh
echo "System packages installed (mosh)"

# -----------------------------------------------------------------------------
# 1Password CLI
# -----------------------------------------------------------------------------
if ! command -v op &>/dev/null; then
  echo "Installing 1Password CLI..."
  ARCH=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
  curl -sSfL "https://downloads.1password.com/linux/debian/${ARCH}/stable/1password-cli-${ARCH}-latest.deb" -o /tmp/1password-cli.deb
  sudo dpkg -i /tmp/1password-cli.deb
  rm /tmp/1password-cli.deb
  echo "1Password CLI installed: $(op --version)"
else
  echo "1Password CLI already installed: $(op --version)"
fi

# -----------------------------------------------------------------------------
# Claude Code
# -----------------------------------------------------------------------------
if [ ! -x "$HOME/.local/bin/claude" ]; then
  echo "Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash
  echo "Claude Code installed"
else
  echo "Claude Code already installed: $($HOME/.local/bin/claude --version 2>/dev/null || echo unknown)"
fi

# -----------------------------------------------------------------------------
# OpenCode
# -----------------------------------------------------------------------------
if [ ! -x "$HOME/.opencode/bin/opencode" ]; then
  echo "Installing OpenCode..."
  curl -fsSL https://opencode.ai/install | bash
  echo "OpenCode installed"
else
  echo "OpenCode already installed: $($HOME/.opencode/bin/opencode --version 2>/dev/null || echo unknown)"
fi

# -----------------------------------------------------------------------------
# Nix (if not installed)
# -----------------------------------------------------------------------------
if ! command -v nix &>/dev/null; then
  echo "Installing Nix..."
  sh <(curl -L https://nixos.org/nix/install) --daemon
  echo "Nix installed - please restart your shell and run this script again"
  exit 0
else
  echo "Nix already installed: $(nix --version)"
fi

# -----------------------------------------------------------------------------
# Home Manager
# -----------------------------------------------------------------------------
if ! command -v home-manager &>/dev/null; then
  echo "Installing Home Manager..."
  nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
  nix-channel --update
  nix-shell '<home-manager>' -A install
  echo "Home Manager installed"
else
  echo "Home Manager already installed"
fi

# -----------------------------------------------------------------------------
# Apply Home Manager configuration
# -----------------------------------------------------------------------------
echo "Applying Home Manager configuration..."
cd ~/dotfiles
home-manager switch --flake .#sandon@linux

echo ""
echo "Bootstrap complete!"
echo ""
echo "Next steps:"
echo "  1. Restart your shell: exec zsh"
echo "  2. Authenticate 1Password: op signin"
echo "  3. Authenticate GitHub CLI: gh auth login"
