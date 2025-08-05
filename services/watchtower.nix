{ config, pkgs, ... }:
let
  composeFile = pkgs.writeText "watchtower-compose.yml" ''
    services:
      watchtower:
        image: containrrr/watchtower
        container_name: watchtower
        restart: unless-stopped
        volumes:
          - /var/run/docker.sock:/var/run/docker.sock
        command: --label-enable --interval 21600 # seconds -> 6 hours

    # Use this to enable watchtower for specific containers
    # labels:
    #   - "com.centurylinklabs.watchtower.enable=true"
  '';
in
{
  # Copy compose file to system
  environment.etc."docker-compose/watchtower/docker-compose.yml".source = composeFile;

  systemd.services.watchtower = {
    description = "Docker Compose service for Watchtower";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = "/etc/docker-compose/watchtower";
      ExecStart = "${pkgs.docker-compose}/bin/docker-compose up -d";
      ExecStop = "${pkgs.docker-compose}/bin/docker-compose down";
      ExecReload = "${pkgs.docker-compose}/bin/docker-compose up -d --force-recreate";
      TimeoutStartSec = 0;
      User = "root";
    };

    unitConfig = {
      StartLimitBurst = 3;
      StartLimitIntervalSec = 60;
    };
  };

  # Create directory (no secrets needed for watchtower)
  systemd.tmpfiles.rules = [
    "d /etc/docker-compose/watchtower 0755 root root -"
  ];
}
