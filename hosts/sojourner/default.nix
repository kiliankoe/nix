{ pkgs, ... }:
{
  imports = [
    ../../modules/darwin/base.nix
    ../../modules/darwin/shared-packages.nix
    ../../modules/shared/base.nix
    ../../modules/shared/tmux.nix
    ../../modules/shared/zsh.nix
    ./packages.nix
  ];

  # Sojourner doesn't use Homebrew (work machine)
  
  # Sojourner-specific system configuration
  nixpkgs.hostPlatform = "aarch64-darwin";
}
