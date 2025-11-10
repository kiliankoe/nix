{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos
    ./packages.nix
  ];

  networking.hostName = "cubesat";
}
