{ config, pkgs, ... }:
let
  dockerService = import ../lib/docker-service.nix { inherit pkgs; };

  composeFile = pkgs.writeText "wbbash-compose.yml" ''
    services:
      wbbash:
        container_name: wbbash
        image: wbbash:latest # TODO: Publish on ghcr.io
        restart: unless-stopped
        environment:
          - DATABASE_URL=file:/db.sqlite
          - MINIQDB_NAME=${builtins.readFile config.sops.secrets."wbbash/miniqdb_name".path}
          - ALLOWED_DOMAINS=${builtins.readFile config.sops.secrets."wbbash/allowed_domains".path}
          - NEXT_PUBLIC_NOTHING_TO_SEE_HERE_BUTTON_TEXT=${
            builtins.readFile config.sops.secrets."wbbash/nothing_to_see_here_text".path
          }
          - NEXT_PUBLIC_LOGIN_BUTTON_TEXT=${
            builtins.readFile config.sops.secrets."wbbash/login_button_text".path
          }
          - NEXTAUTH_SECRET=${builtins.readFile config.sops.secrets."wbbash/nextauth_secret".path}
          - EMAIL_SERVER_HOST=${builtins.readFile config.sops.secrets."wbbash/email_server_host".path}
          - EMAIL_SERVER_PORT=${builtins.readFile config.sops.secrets."wbbash/email_server_port".path}
          - EMAIL_SERVER_USER=${builtins.readFile config.sops.secrets."wbbash/email_server_user".path}
          - EMAIL_SERVER_PASSWORD=${
            builtins.readFile config.sops.secrets."wbbash/email_server_password".path
          }
          - EMAIL_FROM=${builtins.readFile config.sops.secrets."wbbash/email_from".path}
        volumes:
          - wbbash-db:/db.sqlite
        ports:
          - '8386:3000'

    volumes:
      wbbash-db:
  '';
in
dockerService.mkDockerComposeService {
  serviceName = "wbbash";
  composeFile = composeFile;
}
