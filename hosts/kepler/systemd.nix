{ config, pkgs, ... }:
let
  mkCifsMount =
    {
      name,
      description,
      share,
      mountPoint,
      mountOpts,
      dependentServices ? [ ],
      postMount ? "",
    }:
    let
      watchdogName = "${name}-watchdog";
    in
    {
      services.${name} = {
        inherit description;
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ] ++ dependentServices;
        path = [
          pkgs.util-linux
          pkgs.cifs-utils
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          Restart = "on-failure";
          RestartSec = "10s";
          # Allow retries during activation without failing the switch
          StartLimitIntervalSec = 120;
          StartLimitBurst = 5;
          ExecStart = pkgs.writeShellScript "mount-${name}" ''
            mkdir -p ${mountPoint}

            if mountpoint -q ${mountPoint}; then
              echo "Already mounted"
              exit 0
            fi

            for i in $(seq 1 30); do
              [ -f /run/secrets/synology/smb_username ] && break
              echo "Waiting for secrets... ($i/30)"
              sleep 1
            done
            if [ ! -f /run/secrets/synology/smb_username ]; then
              echo "Secrets not available after 30s"
              exit 1
            fi

            if [ ! -f /run/secrets/synology_smb_credentials ]; then
              echo "username=$(cat /run/secrets/synology/smb_username)" > /run/secrets/synology_smb_credentials
              echo "password=$(cat /run/secrets/synology/smb_password)" >> /run/secrets/synology_smb_credentials
              chmod 600 /run/secrets/synology_smb_credentials
            fi

            mount.cifs ${share} ${mountPoint} \
              -o credentials=/run/secrets/synology_smb_credentials,${mountOpts}
            echo "Mount successful"
            ${postMount}
          '';
          ExecStop = pkgs.writeShellScript "umount-${name}" ''
            umount ${mountPoint} 2>/dev/null || true
          '';
        };
      };

      services.${watchdogName} = {
        description = "Check ${name} CIFS mount health and remount if stale";
        path = [
          pkgs.util-linux
          pkgs.cifs-utils
          pkgs.iputils
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript watchdogName ''
            try_remount() {
              if ! ping -c 1 -W 5 marvin > /dev/null 2>&1; then
                echo "marvin unreachable, skipping remount"
                return 1
              fi
              systemctl reset-failed ${name}.service 2>/dev/null || true
              systemctl restart ${name}.service
            }

            if ! mountpoint -q ${mountPoint}; then
              echo "Not mounted, attempting remount"
              if ! try_remount; then
                systemctl stop ${name}.service 2>/dev/null || true
              fi
              exit 0
            fi

            if ! timeout 10 ls ${mountPoint} > /dev/null 2>&1; then
              echo "Mount stale, forcing remount"
              umount -l ${mountPoint} 2>/dev/null || true
              if ! try_remount; then
                systemctl stop ${name}.service
              fi
            fi
          '';
        };
      };
      timers.${watchdogName} = {
        description = "Periodically check ${name} CIFS mount health";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5min";
          OnUnitActiveSec = "5min";
        };
      };
    };

  mediaMount = mkCifsMount {
    name = "media-mount";
    description = "Mount Synology NAS for media services";
    share = "//marvin/Plex";
    mountPoint = "/mnt/media";
    mountOpts = "vers=2.0,uid=0,gid=${toString config.users.groups.media.gid},file_mode=0775,dir_mode=0775";
    dependentServices = [
      "sabnzbd.service"
      "sonarr.service"
      "radarr.service"
      "qbittorrent.service"
    ];
    postMount = "mkdir -p /mnt/media/download/complete /mnt/media/download/incomplete";
  };

  immichMount = mkCifsMount {
    name = "immich-mount";
    description = "Mount Synology NAS for Immich";
    share = "//marvin/photos/immich";
    mountPoint = "/mnt/photos/immich";
    mountOpts = "vers=2.0,uid=1000,gid=100,file_mode=0664,dir_mode=0775";
    dependentServices = [ "immich.service" ];
  };
in
{
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

    services = {
      immich = {
        after = [ "immich-mount.service" ];
        bindsTo = [ "immich-mount.service" ];
      };

      sabnzbd = {
        after = [ "media-mount.service" ];
        bindsTo = [ "media-mount.service" ];
      };
      sonarr = {
        after = [ "media-mount.service" ];
        bindsTo = [ "media-mount.service" ];
      };
      radarr = {
        after = [ "media-mount.service" ];
        bindsTo = [ "media-mount.service" ];
      };
      qbittorrent = {
        after = [ "media-mount.service" ];
        bindsTo = [ "media-mount.service" ];
      };
    }
    // mediaMount.services
    // immichMount.services;

    timers = mediaMount.timers // immichMount.timers;
  };
}
