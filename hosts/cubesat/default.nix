{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base.nix
    # ../../modules/shared/tmux.nix
    ../../modules/shared/zsh.nix
    # ../../services/pangolin.nix
    ./packages.nix
  ];

  networking.hostName = "cubesat";
}
