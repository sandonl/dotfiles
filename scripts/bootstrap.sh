#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Bootstrap Script for Sandon's Development Environment
# =============================================================================
# Sets up a fresh Linux VM as a remote dev environment with:
#   - 1Password CLI (interactive signin to extract SSH key)
#   - SSH key for GitHub auth + git commit signing
#   - Tailscale (mesh VPN for remote access)
#   - Nix + home-manager (declarative config from dotfiles)
#
# PREREQUISITES:
#   1. Store your GitHub SSH key in 1Password as an item named "GH_SSH_KEY"
#      (the private key field will be extracted to ~/.ssh/id_ed25519_signing)
#
#   2. (Optional) Get a Tailscale auth key from:
#      https://login.tailscale.com/admin/settings/keys
#
# USAGE:
#   ./scripts/bootstrap.sh
#   TS_AUTH_KEY='tskey-auth-...' ./scripts/bootstrap.sh   # with Tailscale auto-auth
# =============================================================================

# 1Password item reference for the SSH key
# Format: op://vault/item/field
OP_SSH_KEY_REF="op://Employee/github-dotfiles-vm/private key"

echo "=== Sandon's VM Bootstrap ==="
echo ""

# -----------------------------------------------------------------------------
# Preflight checks
# -----------------------------------------------------------------------------
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
  echo "This script is for Linux only. Use darwin-rebuild on macOS."
  exit 1
fi

if [[ $EUID -eq 0 ]]; then
  echo "Don't run as root. Run as your normal user."
  exit 1
fi

# -----------------------------------------------------------------------------
# [1/8] Install prerequisites
# -----------------------------------------------------------------------------
echo "[1/8] Installing prerequisites..."
NEEDS_INSTALL=()
for cmd in git curl jq tar mosh; do
  if ! command -v "$cmd" &>/dev/null; then
    NEEDS_INSTALL+=("$cmd")
  fi
done

if [[ ${#NEEDS_INSTALL[@]} -gt 0 ]]; then
  sudo apt-get update -qq
  sudo apt-get install -y -qq "${NEEDS_INSTALL[@]}"
  echo "Installed: ${NEEDS_INSTALL[*]}"
else
  echo "Prerequisites already installed."
fi

# -----------------------------------------------------------------------------
# [2/8] Install 1Password CLI
# -----------------------------------------------------------------------------
echo ""
echo "[2/8] Installing 1Password CLI..."
if ! command -v op &>/dev/null; then
  ARCH=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
  curl -sSfL "https://downloads.1password.com/linux/debian/${ARCH}/stable/1password-cli-${ARCH}-latest.deb" -o /tmp/1password-cli.deb
  sudo dpkg -i /tmp/1password-cli.deb
  rm /tmp/1password-cli.deb
  echo "1Password CLI installed: $(op --version)"
else
  echo "1Password CLI already installed: $(op --version)"
fi

# -----------------------------------------------------------------------------
# [3/8] Sign in to 1Password + extract SSH key
# -----------------------------------------------------------------------------
echo ""
echo "[3/8] Setting up SSH key..."
SSH_KEY="$HOME/.ssh/id_ed25519_signing"
if [[ ! -f "$SSH_KEY" ]]; then
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  echo "Signing in to 1Password to extract SSH key..."
  echo "(Approve the prompt on your device)"
  echo ""
  eval "$(op signin)"

  op read "$OP_SSH_KEY_REF" --out-file "$SSH_KEY" --force
  chmod 600 "$SSH_KEY"

  # Convert from PKCS#8 (1Password export format) to OpenSSH format
  if head -1 "$SSH_KEY" | grep -q "BEGIN PRIVATE KEY"; then
    ssh-keygen -p -N "" -f "$SSH_KEY" >/dev/null
    echo "Converted key from PKCS#8 to OpenSSH format."
  fi

  ssh-keygen -y -f "$SSH_KEY" > "${SSH_KEY}.pub"
  chmod 644 "${SSH_KEY}.pub"
  echo "SSH signing key extracted from 1Password."
else
  echo "SSH key already exists."
fi

# Ensure correct permissions
chmod 600 "$SSH_KEY"

# Add to ssh-agent for this session
eval "$(ssh-agent -s)" >/dev/null 2>&1
ssh-add "$SSH_KEY" 2>/dev/null

# -----------------------------------------------------------------------------
# [4/8] Install Tailscale + authenticate
# -----------------------------------------------------------------------------
echo ""
echo "[4/8] Setting up Tailscale..."
if ! command -v tailscale &>/dev/null; then
  curl -fsSL https://tailscale.com/install.sh | sh
  echo "Tailscale installed."
else
  echo "Tailscale already installed."
fi

if ! tailscale status &>/dev/null; then
  if [[ -n "${TS_AUTH_KEY:-}" ]]; then
    sudo tailscale up --authkey="$TS_AUTH_KEY"
    echo "Tailscale authenticated."
  else
    echo "Tailscale not connected. Run manually after bootstrap:"
    echo "  sudo tailscale up"
  fi
else
  echo "Tailscale already connected."
fi

# -----------------------------------------------------------------------------
# [5/8] Install Nix
# -----------------------------------------------------------------------------
echo ""
echo "[5/8] Installing Nix..."
if ! command -v nix &>/dev/null; then
  sh <(curl -L https://nixos.org/nix/install) --daemon
  echo ""
  echo "Nix installed. Please restart your shell and run this script again:"
  echo "  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
  echo "  ./scripts/bootstrap.sh"
  exit 0
else
  echo "Nix already installed: $(nix --version)"
fi

# Ensure flakes and nix-command are enabled
if ! grep -q "experimental-features" /etc/nix/nix.conf 2>/dev/null; then
  echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf >/dev/null
  sudo systemctl restart nix-daemon
  echo "Enabled flakes and nix-command."
fi

# -----------------------------------------------------------------------------
# [6/8] Clone dotfiles via SSH
# -----------------------------------------------------------------------------
echo ""
echo "[6/8] Cloning dotfiles..."
if [[ ! -d "$HOME/dotfiles" ]]; then
  git clone git@github.com:sandonl/dotfiles.git "$HOME/dotfiles"
  echo "Dotfiles cloned."
else
  echo "Dotfiles already cloned. Pulling latest..."
  git -C "$HOME/dotfiles" pull
fi

# -----------------------------------------------------------------------------
# [7/8] Apply home-manager config
# -----------------------------------------------------------------------------
echo ""
echo "[7/8] Applying home-manager config..."
nix run home-manager -- switch -b backup --flake "$HOME/dotfiles#sandon@linux"

# -----------------------------------------------------------------------------
# [8/8] Authenticate GitHub CLI (interactive — device code flow)
# -----------------------------------------------------------------------------
echo ""
echo "[8/8] Authenticating GitHub CLI..."

GH_CMD="nix run nixpkgs#gh --"

if ! $GH_CMD auth status &>/dev/null 2>&1; then
  echo "Starting device code flow..."
  echo "You'll need to visit a URL and enter a code on another device."
  echo ""
  $GH_CMD auth login --git-protocol https --web
  echo "GitHub CLI authenticated."
else
  echo "GitHub CLI already authenticated."
fi

# Configure git to use gh for HTTPS auth (fallback for any HTTPS remotes)
$GH_CMD auth setup-git

# =============================================================================
# Done
# =============================================================================
echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "  1. Restart your shell: exec zsh"
if ! tailscale status &>/dev/null; then
  echo "  2. Connect Tailscale: sudo tailscale up"
fi
echo ""
