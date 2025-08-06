{ config, pkgs, ... }:
let
  dockerService = import ../lib/docker-service.nix { inherit pkgs; };

  composeFile = pkgs.writeText "mato-compose.yml" ''
    services:
      app:
        image: ghcr.io/kiliankoe/mato:latest
        restart: unless-stopped
        environment:
          - TIMEZONE=Europe/Berlin
          - DB_PATH=/data/db.json
          - MY_EMAIL=${builtins.readFile config.sops.secrets."mato/my_email".path}
          - SMTP_HOST=${builtins.readFile config.sops.secrets."mato/smtp_host".path}
          - SMTP_FROM=${builtins.readFile config.sops.secrets."mato/smtp_from".path}
          - SMTP_USER=${builtins.readFile config.sops.secrets."mato/smtp_user".path}
          - SMTP_PASS=${builtins.readFile config.sops.secrets."mato/smtp_pass".path}
          - CATFACT_SLACK_WEBHOOK_URL=${
            builtins.readFile config.sops.secrets."mato/catfact_slack_webhook_url".path
          }
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
dockerService.mkDockerComposeService {
  serviceName = "mato";
  composeFile = composeFile;
}
