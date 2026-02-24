{ ... }:
{
  imports = [
    ../../modules/shared/common.nix
    ../../modules/shared/packages.nix
    ../../modules/shared/packages-workstation.nix
    ../../modules/shared/package-overrides.nix
    ../../modules/shared/sops.nix

    ../../modules/darwin/base.nix
    ../../modules/darwin/packages.nix
    ../../modules/darwin/homebrew.nix

    ./packages.nix
    ./homebrew.nix
  ];

  networking.hostName = "voyager";
  networking.computerName = "Voyager";

  nixpkgs.hostPlatform = "aarch64-darwin";
}
