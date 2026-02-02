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
    ../../services/plausible.nix
    ../../services/foundry-vtt.nix
    ../../services/fredy.nix
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

    services.immich = {
      after = [ "immich-mount.service" ];
      wants = [ "immich-mount.service" ];
    };

    # services.plex = {
    #   after = [ "plex-mount.service" ];
    #   wants = [ "plex-mount.service" ];
    # };

    # Mount service that always succeeds (even if mount fails)
    services.immich-mount = {
      description = "Mount Synology NAS for Immich";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      path = [
        pkgs.util-linux
        pkgs.cifs-utils
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "mount-immich" ''
          set -e

          # Create mount point if needed
          mkdir -p /mnt/photos/immich

          # Skip if already mounted
          if mountpoint -q /mnt/photos/immich; then
            echo "Already mounted"
            exit 0
          fi

          # Generate credentials file from sops secrets
          if [ ! -f /run/secrets/synology/smb_username ]; then
            echo "Secrets not available"
            exit 1
          fi
          echo "username=$(cat /run/secrets/synology/smb_username)" > /run/secrets/synology_smb_credentials
          echo "password=$(cat /run/secrets/synology/smb_password)" >> /run/secrets/synology_smb_credentials
          chmod 600 /run/secrets/synology_smb_credentials

          # Mount the NAS
          mount.cifs //marvin/photos/immich /mnt/photos/immich \
            -o credentials=/run/secrets/synology_smb_credentials,vers=2.0,uid=1000,gid=100,file_mode=0664,dir_mode=0775
          echo "Mount successful"
        '';
        ExecStop = pkgs.writeShellScript "umount-immich" ''
          umount /mnt/photos/immich 2>/dev/null || true
        '';
      };
    };

    # Mount service for Plex media (disabled)
    # services.plex-mount = {
    #   description = "Mount Synology NAS for Plex";
    #   after = [ "network-online.target" ];
    #   wants = [ "network-online.target" ];
    #   path = [
    #     pkgs.util-linux
    #     pkgs.cifs-utils
    #   ];
    #   serviceConfig = {
    #     Type = "oneshot";
    #     RemainAfterExit = true;
    #     ExecStart = pkgs.writeShellScript "mount-plex" ''
    #       set -e
    #
    #       # Create mount point if needed
    #       mkdir -p /mnt/plex
    #
    #       # Skip if already mounted
    #       if mountpoint -q /mnt/plex; then
    #         echo "Already mounted"
    #         exit 0
    #       fi
    #
    #       # Reuse existing credentials file created by immich-mount
    #       # or create one if immich-mount hasn't run
    #       if [ ! -f /run/secrets/synology_smb_credentials ]; then
    #         if [ ! -f /run/secrets/synology/smb_username ]; then
    #           echo "Secrets not available"
    #           exit 1
    #         fi
    #         echo "username=$(cat /run/secrets/synology/smb_username)" > /run/secrets/synology_smb_credentials
    #         echo "password=$(cat /run/secrets/synology/smb_password)" >> /run/secrets/synology_smb_credentials
    #         chmod 600 /run/secrets/synology_smb_credentials
    #       fi
    #
    #       # Mount the NAS - using plex user/group IDs
    #       mount.cifs //marvin/Plex /mnt/plex \
    #         -o credentials=/run/secrets/synology_smb_credentials,vers=2.0,uid=$(id -u plex),gid=$(id -g plex),file_mode=0644,dir_mode=0755
    #       echo "Mount successful"
    #     '';
    #     ExecStop = pkgs.writeShellScript "umount-plex" ''
    #       umount /mnt/plex 2>/dev/null || true
    #     '';
    #   };
    # };
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

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="04b8", ATTR{idProduct}=="0e28", MODE="0666"
  '';

}
