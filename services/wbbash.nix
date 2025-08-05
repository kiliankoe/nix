{ config, pkgs, ... }:
let
  composeFile = pkgs.writeText "wbbash-compose.yml" ''
    services:
      wbbash:
        container_name: wbbash
        image: wbbash:latest # TODO: Publish on ghcr.io
        restart: unless-stopped
        environment:
          - DATABASE_URL=file:/db.sqlite
        env_file:
          - .env
        volumes:
          - wbbash-db:/db.sqlite
        ports:
          - '8386:3000'

    volumes:
      wbbash-db:
  '';
in
{
  # Copy compose files to system
  environment.etc = {
    "docker-compose/wbbash/docker-compose.yml".source = composeFile;
  };

  systemd.services.wbbash = {
    description = "Docker Compose service for WBBash";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = "/etc/docker-compose/wbbash";
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
    "d /etc/docker-compose/wbbash 0755 root root -"
    "L+ /etc/docker-compose/wbbash/.env - - - - /home/kilian/.config/secrets/wbbash.env"
  ];
}
