{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base.nix
    ../../modules/shared/base.nix
    # ../../modules/shared/tmux.nix
    ../../modules/shared/zsh.nix
    ../../services/forgejo.nix
    ../../services/mato.nix
    ../../services/watchtower.nix
    ./packages.nix
  ];

  # Networking
  networking.hostName = "mariner";

  # Disable power management (server)
  powerManagement.enable = false;
  systemd = {
    targets = {
      sleep = {
        enable = false;
        unitConfig.DefaultDependencies = "no";
      };
      suspend = {
        enable = false;
        unitConfig.DefaultDependencies = "no";
      };
      hibernate = {
        enable = false;
        unitConfig.DefaultDependencies = "no";
      };
      "hybrid-sleep" = {
        enable = false;
        unitConfig.DefaultDependencies = "no";
      };
    };
  };

  # WebDAV mount for Tailscale
  services.davfs2.enable = true;
  fileSystems."/mnt/tailscale" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" ];
  };

  systemd.mounts = [
    {
      enable = true;
      description = "Tailscale Drive WebDAV mount";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      what = "http://100.100.100.100:8080";
      where = "/mnt/tailscale";
      options = "uid=1000,gid=100,file_mode=0664,dir_mode=0775,_netdev";
      type = "davfs";
      mountConfig.TimeoutSec = 30;
    }
  ];

  services.cron = {
    enable = true;
    systemCronJobs = [
      # "0 4 * * 1      kilian    sudo rsync -av --progress html /mnt/tailscale/kiliankoe.github/marvin/backups/nextcloud/"
    ];
  };

}
