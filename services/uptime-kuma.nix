{ config, pkgs, ... }:
let
  composeFile = pkgs.writeText "uptime-kuma-compose.yml" ''
    services:
      uptime-kuma:
        image: louislam/uptime-kuma:latest
        container_name: uptime-kuma
        restart: unless-stopped
        security_opt:
          - "no-new-privileges:true"
        volumes:
          - uptime-kuma-data:/app/data
        ports:
          - '8385:3001'

    volumes:
      uptime-kuma-data:
  '';
in
{
  # Copy compose files to system
  environment.etc = {
    "docker-compose/uptime-kuma/docker-compose.yml".source = composeFile;
  };

  systemd.services.uptime-kuma = {
    description = "Docker Compose service for Uptime Kuma";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = "/etc/docker-compose/uptime-kuma";
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
    "d /etc/docker-compose/uptime-kuma 0755 root root -"
  ];
}
