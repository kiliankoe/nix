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
}
