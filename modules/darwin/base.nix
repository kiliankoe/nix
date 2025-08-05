{ pkgs, ... }:
{
  # Nix configuration
  nix.enable = true;
  nix.settings.experimental-features = "nix-command flakes";
  
  # Optimize Nix-Store During Rebuilds
  nix.optimise.automatic = true;
  
  # Purge Unused Nix-Store Entries
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 14d";
  };

  # Enable zsh
  programs.zsh.enable = true;

  # Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # System configuration
  system.stateVersion = 4;
}