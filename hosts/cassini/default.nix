{ pkgs, lib, ... }:
{
  imports = [
    ../../modules/darwin
    ./packages.nix
    ./homebrew.nix
  ];

  networking.hostName = "cassini";
  networking.computerName = "Cassini";

  home-manager.users.kilian = {
    imports = [ ../../home/programs/k9s.nix ];

    programs.git.settings.user.email = "kilian.koeltzsch@wandelbots.com";
  };
}
