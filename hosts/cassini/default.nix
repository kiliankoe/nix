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

  networking.hostName = "cassini";
  networking.computerName = "Cassini";

  nixpkgs.hostPlatform = "aarch64-darwin";

  home-manager.users.kilian = {
    imports = [ ../../home/programs/k9s.nix ];

    programs.git.settings.user.email = "kilian.koeltzsch@wandelbots.com";

    programs.git.includes = [
      {
        condition = "gitdir:~/dev/personal/";
        contents.user.email = "me@kilian.io";
      }
    ];
  };
}
