{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/shared/common.nix
    ../../modules/nixos/base.nix
    # ../../services/pangolin.nix
    ./packages.nix
  ];

  networking.hostName = "cubesat";
}
