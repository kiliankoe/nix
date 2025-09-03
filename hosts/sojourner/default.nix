{ pkgs, ... }:
{
  imports = [
    ../../modules/shared/common.nix
    ../../modules/shared/packages.nix
    ../../modules/shared/sops.nix

    ../../modules/darwin/base.nix
    ../../modules/darwin/packages.nix
    ../../modules/darwin/homebrew.nix

    ./packages.nix
    ./homebrew.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  home-manager.users.kilian = {
    imports = [ ../../home/programs/k9s.nix ];
    
    programs.git = {
      userEmail = "kilian.koeltzsch@wandelbots.com";
    };
  };
}
