{ config, pkgs, lib, ... }:

# Workstation configuration - macOS desktop apps and their configs
{
  # =============================================================================
  # Additional Packages (workstation-only)
  # =============================================================================
  home.packages = with pkgs; [
    # Additional tools for workstation
    bat

    # Fonts (for terminal rendering)
    nerd-fonts.meslo-lg
    nerd-fonts.jetbrains-mono
  ];

  # =============================================================================
  # App Configurations
  # =============================================================================

  # Ghostty terminal
  home.file."Library/Application Support/com.mitchellh.ghostty/config".source =
    ../home/dotfiles/ghostty.conf;


  # =============================================================================
  # FZF (workstation gets full integration)
  # =============================================================================
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
    ];
  };

  # =============================================================================
  # Bat (better cat)
  # =============================================================================
  programs.bat = {
    enable = true;
    config = {
      theme = "Solarized (dark)";
      style = "numbers,changes";
    };
  };
}
