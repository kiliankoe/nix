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

    # Monitoring stack (Prometheus + Grafana + AlertManager)
    ../../services/monitoring

    # Docker-based services
    ../../services/foundry-vtt.nix
    ../../services/immich.nix
    ../../services/lehmuese.nix
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
    "synology/smb_username" = { };
    "synology/smb_password" = { };
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

    services.synology-smb-credentials = {
      description = "Generate CIFS credentials file for Synology mount";
      before = [ "mnt-photos-immich.mount" ];
      requiredBy = [ "mnt-photos-immich.mount" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "gen-cifs-creds" ''
          echo "username=$(cat /run/secrets/synology/smb_username)" > /run/secrets/synology_smb_credentials
          echo "password=$(cat /run/secrets/synology/smb_password)" >> /run/secrets/synology_smb_credentials
          chmod 600 /run/secrets/synology_smb_credentials
        '';
      };
    };

    services.immich = {
      after = [ "mnt-photos-immich.mount" ];
      requires = [ "mnt-photos-immich.mount" ];
    };
  };

  fileSystems."/mnt/photos/immich" = {
    device = "//marvin/photos/immich";
    fsType = "cifs";
    options = [
      "credentials=/run/secrets/synology_smb_credentials"
      "vers=3.1.1"
      "uid=1000"
      "gid=100"
      "file_mode=0664"
      "dir_mode=0775"
      "_netdev"
      "x-systemd.automount"
      "x-systemd.requires=network-online.target"
    ];
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
