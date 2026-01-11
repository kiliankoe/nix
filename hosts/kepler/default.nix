{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix

    ../../modules/shared/common.nix
    ../../modules/shared/packages.nix
    ../../modules/shared/sops.nix

    ../../modules/nixos/base.nix

    ./packages.nix

    ../../services/changedetection.nix
    ../../services/cockpit.nix
    ../../services/freshrss.nix
    ../../services/paperless.nix
    ../../services/uptime-kuma.nix

    # Unified backup for all services
    ../../services/backup.nix

    # Docker-based services
    ../../services/foundry-vtt.nix
    ../../services/linkding.nix
    ../../services/mato.nix
    ../../services/newsdiff.nix
    ../../services/speedtest-tracker.nix
    ../../services/swiftdebot.nix
    ../../services/watchtower.nix
    ../../services/wbbash.nix

    # Automation
    ../../services/flake-updater.nix
  ];

  networking.hostName = "kepler";

  home-manager.users.kilian = {
    programs.tmux.extraConfig = ''
      set -g status-bg green
      set -g status-fg black
      set -g pane-active-border-style bg=default,fg=green
    '';
    programs.starship.settings.hostname.format = "[$hostname ](bold green)";
  };

  # db shared by multiple services
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;

    # Ensure all required databases and users exist
    ensureDatabases = [
      "freshrss"
      "paperless"
    ];
    ensureUsers = [
      {
        name = "freshrss";
        ensureDBOwnership = true;
      }
      {
        name = "paperless";
        ensureDBOwnership = true;
      }
    ];
  };

  sops.secrets = {
    "kepler_backup/server" = { };
    "kepler_backup/username" = { };
    "kepler_backup/password" = { };
  };

  # Disable power management (server)
  powerManagement.enable = false;
  # Set CPU governor to performance for better responsiveness
  powerManagement.cpuFreqGovernor = "performance";

  # Add swap to prevent performance degradation under memory pressure
  swapDevices = [
    {
      device = "/swapfile";
      size = 8192;
    }
  ];

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
  # services.davfs2.enable = true;
  # fileSystems."/mnt/tailscale" = {
  #   device = "none";
  #   fsType = "tmpfs";
  #   options = [ "defaults" ];
  # };

  # systemd.mounts = [
  #   {
  #     enable = true;
  #     description = "Tailscale Drive WebDAV mount";
  #     after = [ "network-online.target" ];
  #     wants = [ "network-online.target" ];
  #     what = "http://100.100.100.100:8080";
  #     where = "/mnt/tailscale";
  #     options = "uid=1000,gid=100,file_mode=0664,dir_mode=0775,_netdev";
  #     type = "davfs";
  #     mountConfig.TimeoutSec = 30;
  #   }
  # ];

  services.cron = {
    enable = true;
    systemCronJobs = [
      # "0 4 * * 1      kilian    sudo rsync -av --progress html /mnt/tailscale/kiliankoe.github/marvin/backups/nextcloud/"
    ];
  };

}
