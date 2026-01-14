# Sandon's Dotfiles

Reproducible development environment using Nix Flakes, home-manager, and nix-darwin.

## Quick Start

### macOS (First Time)

```bash
# 1. Install Nix
curl -L https://nixos.org/nix/install | sh

# 2. Clone this repo
git clone https://github.com/sandonl/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 3. Apply configuration
nix run nix-darwin -- switch --flake .#macbook-pro

# 4. Restart your shell
exec zsh
```

### Linux VM

```bash
# 1. Clone this repo
git clone https://github.com/sandonl/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. Run bootstrap script (installs Nix, home-manager, CLIs)
./scripts/bootstrap.sh

# 3. Restart your shell
exec zsh
```

## Updating

```bash
# macOS
darwin-rebuild switch --flake ~/dotfiles#macbook-pro

# Linux
home-manager switch --flake ~/dotfiles#sandon@linux
```

## What's Included

### CLI Tools
- **git**, **gh** (GitHub CLI), **lazygit**
- **neovim**, **tmux**
- **ripgrep**, **fd**, **fzf**, **eza**, **zoxide**
- **btop**, **htop**, **jq**, **tree**
- **direnv** with nix-direnv

### Shell
- **zsh** with Oh My Zsh
- **Powerlevel10k** theme
- **1Password SSH Agent** integration

### AI Coding Tools (auto-installed)
- Claude Code
- OpenCode
- Codex (if npm available)

### macOS Apps (configured)
- Ghostty terminal
- Zed editor
- Cursor editor

### macOS System Preferences
- Dock: autohide, no recents
- Finder: show extensions, pathbar
- Touch ID for sudo
- Tailscale service

### Theme
- **poimandres** (dark) / **One Light** (light)
- **JetBrains Mono** font (installed via Nix)

## SSH Key Setup (1Password)

1. Install 1Password and enable SSH Agent in Settings > Developer
2. Create an SSH key in 1Password (Ed25519 recommended)
3. Get your public key:
   ```bash
   ssh-add -L | grep ed25519
   ```
4. Add the key to your `~/.gitconfig`:
   ```ini
   [user]
       signingkey = ssh-ed25519 AAAA...
   ```
5. Add the key to GitHub: Settings > SSH and GPG keys

## Secrets

Copy the example and fill in your values:
```bash
cp .secrets.example ~/.secrets
```

This file is sourced by zshrc and should never be committed.

## Structure

```
dotfiles/
├── flake.nix           # Main entry point
├── home/
│   ├── core.nix        # Cross-platform config
│   ├── workstation.nix # macOS-specific
│   └── dotfiles/       # Actual dotfiles
├── darwin/
│   └── system.nix      # macOS system preferences
├── configs/            # App configs (Zed, Cursor)
└── scripts/            # Bootstrap scripts
```
