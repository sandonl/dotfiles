#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Tailscale Setup Script
# =============================================================================
# Installs and configures Tailscale on macOS or Linux
# Usage: ./scripts/setup-tailscale.sh [--ssh]
# =============================================================================

SSH_FLAG=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --ssh) SSH_FLAG="--ssh"; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo "Setting up Tailscale..."

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  OS="linux"
else
  echo "Unsupported OS: $OSTYPE"
  exit 1
fi

# Install Tailscale if needed
if ! command -v tailscale &>/dev/null; then
  echo "Installing Tailscale..."
  if [[ "$OS" == "macos" ]]; then
    echo "Please install Tailscale from the App Store or https://tailscale.com/download/mac"
    exit 1
  else
    curl -fsSL https://tailscale.com/install.sh | sh
  fi
fi

# Start Tailscale daemon if needed
if [[ "$OS" == "linux" ]]; then
  if ! systemctl is-active --quiet tailscaled; then
    echo "Starting Tailscale daemon..."
    sudo systemctl enable --now tailscaled
  fi
fi

# Check if already connected
if tailscale status &>/dev/null; then
  echo "Tailscale is already connected:"
  tailscale status
else
  echo "Connecting to Tailscale..."
  if [[ -n "$SSH_FLAG" ]]; then
    sudo tailscale up --ssh
  else
    sudo tailscale up
  fi
fi

echo ""
echo "Tailscale setup complete!"
tailscale ip -4
