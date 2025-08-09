{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/shared/common.nix
    ../../modules/nixos/base.nix
    ../../services/pangolin.nix
    ../../services/crowdsec.nix
    ./packages.nix
  ];

  networking.hostName = "cubesat";

  services.pangolin = {
    enable = true;
  };

  services.crowdsec = {
    enable = true;
    enableFirewallBouncer = true;
  };
}
