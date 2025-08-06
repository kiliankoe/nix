{ config, pkgs, ... }:
let
  composeFile = pkgs.writeText "paperless-compose.yml" ''
    services:
      broker:
        image: docker.io/library/redis:8
        restart: unless-stopped
        volumes:
          - paperless-redis-data:/data

      db:
        image: docker.io/library/postgres:17
        restart: unless-stopped
        volumes:
          - paperless-postgres-data:/var/lib/postgresql/data
        healthcheck:
          test: ["CMD-SHELL", "pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB"]
          interval: 5s
          timeout: 20s
          retries: 10

      webserver:
        image: ghcr.io/paperless-ngx/paperless-ngx:latest
        restart: unless-stopped
        depends_on:
          db:
            condition: service_healthy
          broker:
            condition: service_started
        volumes:
          - paperless-data:/usr/src/paperless/data
          - paperless-media:/usr/src/paperless/media
          - paperless-export:/usr/src/paperless/export
          - paperless-consume:/usr/src/paperless/consume
        environment:
          - PAPERLESS_REDIS=redis://broker:6379
          - PAPERLESS_DBHOST=db
          - USERMAP_UID=1000
          - USERMAP_GID=1000
          - PAPERLESS_TIME_ZONE=Europe/Berlin
          - PAPERLESS_OCR_LANGUAGE=deu
          - PAPERLESS_SECRET_KEY=${builtins.readFile config.sops.secrets."paperless/secret_key".path}
        ports:
          - '8382:8000'

    volumes:
      paperless-data:
      paperless-media:
      paperless-postgres-data:
      paperless-redis-data:
      paperless-export:
      paperless-consume:
  '';
in
{
  # Copy compose files to system
  environment.etc = {
    "docker-compose/paperless/docker-compose.yml".source = composeFile;
  };

  systemd.services.paperless = {
    description = "Docker Compose service for Paperless";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = "/etc/docker-compose/paperless";
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
    "d /etc/docker-compose/paperless 0755 root root -"
  ];
}
