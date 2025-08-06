{ config, pkgs, ... }:
let
  dockerService = import ../lib/docker-service.nix { inherit pkgs; };

  composeFile = pkgs.writeText "forgejo-compose.yml" ''
    services:
      app:
        image: 'codeberg.org/forgejo/forgejo:8'
        restart: unless-stopped
        env_file:
          - app.env
        environment:
          - USER_UID=1000
          - USER_GID=1000
        volumes:
          - 'forgejo-data:/data'
        ports:
          - '22222:22'
          - '8378:3000'
        depends_on:
          db:
            condition: service_healthy
        healthcheck:
          test:
            - CMD
            - curl
            - '-f'
            - 'http://127.0.0.1:3000'
          interval: 2s
          timeout: 10s
          retries: 15
        labels:
          - docker-volume-backup.stop-during-backup=true

      db:
        image: 'postgres:16-alpine'
        restart: unless-stopped
        volumes:
          - 'forgejo-postgresql-data:/var/lib/postgresql/data'
        env_file:
          - db.env
        healthcheck:
          test: ["CMD-SHELL", "pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB"]
          interval: 5s
          timeout: 20s
          retries: 10
        labels:
          - docker-volume-backup.stop-during-backup=true

    volumes:
      forgejo-data:
      forgejo-postgresql-data:
  '';

in
dockerService.mkDockerComposeService {
  serviceName = "forgejo";
  composeFile = composeFile;
  volumesToBackup = [
    "forgejo-data"
    "forgejo-postgresql-data"
  ];
  environment = {
    db = {
      POSTGRES_DB = "forgejo";
      POSTGRES_USER = "forgejo";
      POSTGRES_PASSWORD = {
        secretFile = config.sops.secrets."forgejo/postgres_password".path;
      };
    };
    app = {
      FORGEJO__server__ROOT_URL = {
        secretFile = config.sops.secrets."forgejo/root_url".path;
      };
      FORGEJO__server__SSH_PORT = {
        secretFile = config.sops.secrets."forgejo/ssh_port".path;
      };
      FORGEJO__server__DEFAULT_UI_LOCATION = "Europe/Berlin";
      FORGEJO__database__DB_TYPE = "postgres";
      FORGEJO__database__HOST = "db";
      FORGEJO__database__NAME = "forgejo";
      FORGEJO__database__USER = "forgejo";
      FORGEJO__database__PASSWD = {
        secretFile = config.sops.secrets."forgejo/postgres_password".path;
      };
    };
  };
}
