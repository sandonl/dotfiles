{ config, pkgs, ... }:

{
  # Nix Settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # Primary user (required for system.defaults)
  system.primaryUser = "sandonlai";

  # System Packages
  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  # macOS System Preferences
  system.defaults = {
    dock = {
      autohide = true;
      show-recents = false;
    };

    finder = {
      AppleShowAllExtensions = true;
      ShowPathbar = true;
    };

    NSGlobalDomain = {
      ApplePressAndHoldEnabled = false;
    };
  };

  # Services
  services.tailscale.enable = true;

  # Security - Touch ID for sudo (new option name)
  security.pam.services.sudo_local.touchIdAuth = true;

  # System State Version
  system.stateVersion = 5;
}
