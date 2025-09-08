{ config, pkgs, ... }:
let
  dockerService = import ../lib/docker-service.nix { inherit pkgs; };

  composeFile = pkgs.writeText "wbbash-compose.yml" ''
    services:
      wbbash:
        container_name: wbbash
        image: ghcr.io/kiliankoe/wbbash:main
        restart: unless-stopped
        environment:
          - DATABASE_URL=file:/db.sqlite
        env_file:
          - wbbash.env
        volumes:
          - wbbash-db:/db.sqlite
        ports:
          - '${toString config.k.ports.wbbash_http}:3000'

    volumes:
      wbbash-db:
  '';
in
dockerService.mkDockerComposeService {
  serviceName = "wbbash";
  composeFile = composeFile;
  environment = {
    wbbash = {
      MINIQDB_NAME = {
        secretFile = config.sops.secrets."wbbash/miniqdb_name".path;
      };
      ALLOWED_DOMAINS = {
        secretFile = config.sops.secrets."wbbash/allowed_domains".path;
      };
      NEXT_PUBLIC_NOTHING_TO_SEE_HERE_BUTTON_TEXT = {
        secretFile = config.sops.secrets."wbbash/nothing_to_see_here_text".path;
      };
      NEXT_PUBLIC_LOGIN_BUTTON_TEXT = {
        secretFile = config.sops.secrets."wbbash/login_button_text".path;
      };
      NEXTAUTH_SECRET = {
        secretFile = config.sops.secrets."wbbash/nextauth_secret".path;
      };
      EMAIL_SERVER_HOST = {
        secretFile = config.sops.secrets."wbbash/email_server_host".path;
      };
      EMAIL_SERVER_PORT = {
        secretFile = config.sops.secrets."wbbash/email_server_port".path;
      };
      EMAIL_SERVER_USER = {
        secretFile = config.sops.secrets."wbbash/email_server_user".path;
      };
      EMAIL_SERVER_PASSWORD = {
        secretFile = config.sops.secrets."wbbash/email_server_password".path;
      };
      EMAIL_FROM = {
        secretFile = config.sops.secrets."wbbash/email_from".path;
      };
    };
  };
}
