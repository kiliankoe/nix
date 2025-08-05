{ config, pkgs, ... }:
let
  composeFile = pkgs.writeText "swiftdebot-compose.yml" ''
    services:
      swiftdebot:
        image: ghcr.io/swiftde/swiftdebot:latest
        container_name: swiftdebot
        restart: unless-stopped
        env_file:
          - .env
  '';
in
{
  # Copy compose files to system
  environment.etc = {
    "docker-compose/swiftdebot/docker-compose.yml".source = composeFile;
  };

  systemd.services.swiftdebot = {
    description = "Docker Compose service for SwiftdeBot";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = "/etc/docker-compose/swiftdebot";
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

  # Create secrets symlink for .env file
  systemd.tmpfiles.rules = [
    "d /etc/docker-compose/swiftdebot 0755 root root -"
    "L+ /etc/docker-compose/swiftdebot/.env - - - - /home/kilian/.config/secrets/swiftdebot.env"
  ];
}
