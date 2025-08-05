{ pkgs, ... }:
{
  imports = [
    ../../modules/darwin/base.nix
    ../../modules/shared/dev-tools.nix
    ../../modules/shared/tmux.nix
    ../../modules/shared/zsh.nix
    ../../packages/sojourner-packages.nix
  ];

  # Sojourner doesn't use Homebrew (work machine)
  
  # Sojourner-specific system configuration
  nixpkgs.hostPlatform = "aarch64-darwin";
}