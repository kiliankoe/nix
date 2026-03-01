{ pkgs, ... }:
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

    services.immich = {
      after = [ "immich-mount.service" ];
      wants = [ "immich-mount.service" ];
    };

    services.sabnzbd = {
      after = [ "media-mount.service" ];
      wants = [ "media-mount.service" ];
    };
    services.sonarr = {
      after = [ "media-mount.service" ];
      wants = [ "media-mount.service" ];
    };
    services.radarr = {
      after = [ "media-mount.service" ];
      wants = [ "media-mount.service" ];
    };

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

    services.media-mount = {
      description = "Mount Synology NAS for media services";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      path = [
        pkgs.util-linux
        pkgs.cifs-utils
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "mount-media" ''
          set -e

          mkdir -p /mnt/media

          if mountpoint -q /mnt/media; then
            echo "Already mounted"
            exit 0
          fi

          if [ ! -f /run/secrets/synology/smb_username ]; then
            echo "Secrets not available"
            exit 1
          fi

          # Reuse existing credentials file or create one
          if [ ! -f /run/secrets/synology_smb_credentials ]; then
            echo "username=$(cat /run/secrets/synology/smb_username)" > /run/secrets/synology_smb_credentials
            echo "password=$(cat /run/secrets/synology/smb_password)" >> /run/secrets/synology_smb_credentials
            chmod 600 /run/secrets/synology_smb_credentials
          fi

          MEDIA_GID=$(getent group media | cut -d: -f3)
          mount.cifs //marvin/Plex /mnt/media \
            -o credentials=/run/secrets/synology_smb_credentials,vers=2.0,uid=0,gid="$MEDIA_GID",file_mode=0775,dir_mode=0775
          echo "Mount successful"
        '';
        ExecStop = pkgs.writeShellScript "umount-media" ''
          umount /mnt/media 2>/dev/null || true
        '';
      };
    };
  };
}
