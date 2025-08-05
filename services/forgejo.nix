{ config, pkgs, ... }:
let
  composeFile = pkgs.writeText "forgejo-compose.yml" ''
    services:
      app:
        image: 'codeberg.org/forgejo/forgejo:8'
        restart: unless-stopped
        env_file:
          - .env
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
          - .env
        healthcheck:
          test:
            - CMD-SHELL
            - 'pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}'
          interval: 5s
          timeout: 20s
          retries: 10
        labels:
          - docker-volume-backup.stop-during-backup=true

      backup:
        image: offen/docker-volume-backup:v2
        restart: always
        env_file: ./backup.env
        volumes:
          - /home/kilian/.ssh/id_ed25519:/root/.ssh/id_ed25519:ro
          - /var/run/docker.sock:/var/run/docker.sock:ro
          - forgejo-data:/backup/forgejo:ro
          - forgejo-postgresql-data:/backup/forgejo-postgres:ro

    volumes:
      forgejo-data:
      forgejo-postgresql-data:
  '';

  backupEnvFile = pkgs.writeText "forgejo-backup.env" ''
    # https://offen.github.io/docker-volume-backup/reference/

    BACKUP_CRON_EXPRESSION=0 4 * * *

    # BACKUP_RETENTION_DAYS=90
    # BACKUP_PRUNING_PREFIX=

    # NOTIFICATION_LEVEL="error"
    # NOTIFICATION_URLS="smtp://username:password@host:587/?fromAddress=sender@example.com&toAddresses=recipient@example.com"

    # Additional local file storage
    # BACKUP_ARCHIVE="/archive"

    # Backup destination
    SSH_HOST_NAME=marvin
    SSH_PORT=43593
    SSH_REMOTE_PATH=/volume1/Backups/kepler/forgejo
    SSH_USER=kilian
    SSH_IDENTITY_FILE="/root/.ssh/id_ed25519"
  '';
in
{
  # Copy compose files to system
  environment.etc = {
    "docker-compose/forgejo/docker-compose.yml".source = composeFile;
    "docker-compose/forgejo/backup.env".source = backupEnvFile;
  };

  # Systemd service for Forgejo stack
  systemd.services.docker-compose-forgejo = {
    description = "Docker Compose service for Forgejo";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = "/etc/docker-compose/forgejo";
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
    "d /etc/docker-compose/forgejo 0755 root root -"
    "L+ /etc/docker-compose/forgejo/.env - - - - /home/kilian/.config/secrets/forgejo.env"
  ];
}
