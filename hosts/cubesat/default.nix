{ lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/shared/common.nix
    ../../modules/shared/packages.nix
    ../../modules/shared/sops.nix
    ../../modules/nixos/base.nix
    ./services/pangolin.nix
    ./services/cubesat-backup.nix
  ];

  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  networking.hostName = "cubesat";

  home-manager.users.kilian = {
    programs.tmux.extraConfig = ''
      set -g status-bg yellow
      set -g status-fg black
      set -g pane-active-border-style bg=default,fg=yellow
    '';
    programs.starship.settings.hostname.format = "[$hostname ](bold yellow)";
  };
}
