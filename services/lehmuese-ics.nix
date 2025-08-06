{ config, pkgs, ... }:
let
  composeFile = pkgs.writeText "lehmuese-ics-compose.yml" ''
    services:
      lehmuese-ics:
        container_name: lehmuese-ics
        image: lehmuese-ics:latest # TODO: Publish on ghcr.io
        restart: unless-stopped
        environment:
          - URL=${builtins.readFile config.sops.secrets."lehmuese_ics/url".path}
        volumes:
          - lehmuese-ics-db:/app/db.sqlite
        ports:
          - '8380:3000'

    volumes:
      lehmuese-ics-db:
  '';
in
{
  # Copy compose files to system
  environment.etc = {
    "docker-compose/lehmuese-ics/docker-compose.yml".source = composeFile;
  };

  systemd.services.lehmuese-ics = {
    description = "Docker Compose service for Lehmuese ICS";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = "/etc/docker-compose/lehmuese-ics";
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

  # Create directory for compose files
  systemd.tmpfiles.rules = [
    "d /etc/docker-compose/lehmuese-ics 0755 root root -"
  ];
}
