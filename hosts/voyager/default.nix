{ pkgs, ... }:
{
  imports = [
    ../../modules/shared/base.nix
    ../../modules/shared/sops.nix

    ../../modules/darwin/base.nix
    ../../modules/darwin/packages.nix
    ../../modules/darwin/homebrew.nix

    ./packages.nix
    ./homebrew.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";
}
