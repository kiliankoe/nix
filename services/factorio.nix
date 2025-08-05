{ config, pkgs, ... }:
let
  composeFile = pkgs.writeText "factorio-compose.yml" ''
    services:
      factorio:
        image: factoriotools/factorio:stable
        container_name: factorio
        restart: unless-stopped
        security_opt:
          - "no-new-privileges:true"
        ports:
          - "34197:34197/udp"
        volumes:
          - factorio-data:/factorio
        environment:
          - GENERATE_NEW_SAVE=true
          - DLC_SPACE_AGE=true
        env_file:
          - .env

    volumes:
      factorio-data:
  '';
in
{
  # Copy compose files to system
  environment.etc = {
    "docker-compose/factorio/docker-compose.yml".source = composeFile;
  };

  systemd.services.factorio = {
    description = "Docker Compose service for Factorio";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = "/etc/docker-compose/factorio";
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
    "d /etc/docker-compose/factorio 0755 root root -"
    "L+ /etc/docker-compose/factorio/.env - - - - /home/kilian/.config/secrets/factorio.env"
  ];
}
