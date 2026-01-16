{
  config,
  pkgs,
  lib,
  ...
}:
let
  dockerService = import ../lib/docker-service.nix { inherit pkgs lib; };
in
dockerService.mkDockerComposeService {
  serviceName = "wbbash";
  monitoring.httpEndpoint = {
    name = "wbbash";
    url = "http://localhost:${toString config.k.ports.wbbash_http}/";
  };
  compose = {
    services.wbbash = {
      container_name = "wbbash";
      image = "ghcr.io/kiliankoe/wbbash:main";
      restart = "unless-stopped";
      environment = [
        "DATABASE_URL=file:/data/db.sqlite"
      ];
      env_file = [ "wbbash.env" ];
      volumes = [ "wbbash-db:/data" ];
      ports = [ "${toString config.k.ports.wbbash_http}:3000" ];
    };
    volumes.wbbash-db = { };
  };
  environment = {
    wbbash = {
      MINIQDB_NAME.secret = "wbbash/miniqdb_name";
      ALLOWED_DOMAINS.secret = "wbbash/allowed_domains";
      NEXT_PUBLIC_NOTHING_TO_SEE_HERE_BUTTON_TEXT.secret = "wbbash/nothing_to_see_here_text";
      NEXT_PUBLIC_LOGIN_BUTTON_TEXT.secret = "wbbash/login_button_text";
      NEXTAUTH_SECRET.secret = "wbbash/nextauth_secret";
      EMAIL_SERVER_HOST.secret = "wbbash/email_server_host";
      EMAIL_SERVER_PORT.secret = "wbbash/email_server_port";
      EMAIL_SERVER_USER.secret = "wbbash/email_server_user";
      EMAIL_SERVER_PASSWORD.secret = "wbbash/email_server_password";
      EMAIL_FROM.secret = "wbbash/email_from";
    };
  };
}
