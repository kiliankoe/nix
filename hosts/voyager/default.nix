{ pkgs, ... }:
{
  imports = [
    ../../modules/darwin
    ./packages.nix
    ./homebrew.nix
  ];

  networking.hostName = "voyager";
  networking.computerName = "Voyager";
}
