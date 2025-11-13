{ config, pkgs, ... }:
let
  dockerService = import ../lib/docker-service.nix { inherit pkgs; };

  composeFile = pkgs.writeText "mato-compose.yml" ''
    services:
      app:
        image: ghcr.io/kiliankoe/mato:latest
        restart: unless-stopped
        environment:
          - TIMEZONE=${config.time.timeZone}
          - DB_PATH=/data/db.json
        env_file:
          - mato.env
        volumes:
          - mato-data:/data
        ports:
          - '${toString config.k.ports.mato_http}:5050'
        healthcheck:
          test:
            - CMD
            - curl
            - '-f'
            - 'http://127.0.0.1:5050/webhook'
          interval: 2s
          timeout: 10s
          retries: 15
        labels:
          - "com.centurylinklabs.watchtower.enable=true"

    volumes:
      mato-data:
  '';
in
dockerService.mkDockerComposeService {
  serviceName = "mato";
  composeFile = composeFile;
  environment = {
    mato = {
      MY_EMAIL = {
        secretFile = config.sops.secrets."mato/my_email".path;
      };
      SMTP_HOST = {
        secretFile = config.sops.secrets."mato/smtp_host".path;
      };
      SMTP_FROM = {
        secretFile = config.sops.secrets."mato/smtp_from".path;
      };
      SMTP_USER = {
        secretFile = config.sops.secrets."mato/smtp_user".path;
      };
      SMTP_PASS = {
        secretFile = config.sops.secrets."mato/smtp_pass".path;
      };
      CATFACT_SLACK_WEBHOOK_URL = {
        secretFile = config.sops.secrets."mato/catfact_slack_webhook".path;
      };
      JOBDIFF_SLACK_WEBHOOK_URL = {
        secretFile = config.sops.secrets."mato/jobdiff_slack_webhook".path;
      };
      KAGI_API_TOKEN = {
        secretFile = config.sops.secrets."mato/kagi_api_token".path;
      };
    };
  };
}
