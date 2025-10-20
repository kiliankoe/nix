{ pkgs, lib, ... }:
{
  imports = [
    ../../modules/shared/common.nix
    ../../modules/shared/packages.nix
    ../../modules/shared/package-overrides.nix
    ../../modules/shared/sops.nix

    ../../modules/darwin/base.nix
    ../../modules/darwin/packages.nix
    ../../modules/darwin/homebrew.nix

    ./packages.nix
    ./homebrew.nix
  ];

  # this machine uses determinate nix
  nix.enable = lib.mkForce false;
  nix.gc.automatic = lib.mkForce false;
  nix.optimise.automatic = lib.mkForce false;

  networking.hostName = "cassini";
  networking.computerName = "Cassini";

  nixpkgs.hostPlatform = "aarch64-darwin";

  home-manager.users.kilian = {
    imports = [ ../../home/programs/k9s.nix ];

    programs.git.settings.user.email = "kilian.koeltzsch@wandelbots.com";
  };
}
