{ pkgs, ... }:
{
  imports = [
    ../../modules/darwin/base.nix
    ../../modules/darwin/homebrew.nix
    ../../modules/darwin/shared-packages.nix
    ../../modules/shared/base.nix
    ../../modules/shared/tmux.nix
    ../../modules/shared/zsh.nix
    ./packages.nix
    ./casks.nix
  ];

  system.primaryUser = "kilian";
  nixpkgs.hostPlatform = "aarch64-darwin";
}
