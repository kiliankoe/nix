{ config, pkgs, ... }:
let
  composeFile = pkgs.writeText "mato-compose.yml" ''
    services:
      app:
        image: ghcr.io/kiliankoe/mato:latest
        restart: unless-stopped
        env_file:
          - .env
        environment:
          - TIMEZONE=Europe/Berlin
          - DB_PATH=/data/db.json
        volumes:
          - mato-data:/data
        ports:
          - '12123:5050'
        healthcheck:
          test:
            - CMD
            - curl
            - '-f'
            - 'http://127.0.0.1:5050/webhook'
          interval: 2s
          timeout: 10s
          retries: 15

    volumes:
      mato-data:
  '';
in
{
  # Copy compose file to system
  environment.etc."docker-compose/mato/docker-compose.yml".source = composeFile;

  # Systemd service for Mato
  systemd.services.docker-compose-mato = {
    description = "Docker Compose service for Mato";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = "/etc/docker-compose/mato";
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
    "d /etc/docker-compose/mato 0755 root root -"
    "L+ /etc/docker-compose/mato/.env - - - - /home/kilian/.config/secrets/mato.env"
  ];
}
