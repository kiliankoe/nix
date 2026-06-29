{
  config,
  pkgs,
  lib,
  ...
}:
let
  dockerService = import ../../../../lib/docker-service.nix { inherit pkgs lib; };
in
dockerService.mkDockerComposeService {
  serviceName = "wbbash";
  auto_update = true;
  backupVolumes = [ "wbbash-pb-data" ];
  monitoring.httpEndpoint = {
    name = "wbbash";
    url = "http://localhost:${toString config.k.ports.wbbash_http}/";
  };
  compose = {
    services.wbbash = {
      container_name = "wbbash";
      image = "ghcr.io/kiliankoe/miniqdb:main";
      restart = "unless-stopped";
      env_file = [ "wbbash.env" ];
      depends_on = [ "pocketbase" ];
      ports = [ "${toString config.k.ports.wbbash_http}:80" ];
    };
    # This service name MUST be `pocketbase`.
    services.pocketbase = {
      container_name = "wbbash-pocketbase";
      image = "ghcr.io/kiliankoe/miniqdb-pocketbase:main";
      restart = "unless-stopped";
      env_file = [ "pocketbase.env" ];
      volumes = [ "wbbash-pb-data:/pb/pb_data" ];
      # Localhost-only: admin UI + data migration
      ports = [ "127.0.0.1:8090:8090" ];
    };
    volumes.wbbash-pb-data = { };
  };
  environment = {
    wbbash = {
      APP_NAME.secret = "wbbash/miniqdb_name";
      LOGIN_BUTTON_TEXT.secret = "wbbash/login_button_text";
      NOTHING_TO_SEE_HERE_BUTTON_TEXT.secret = "wbbash/nothing_to_see_here_text";
    };
    pocketbase = {
      ALLOWED_DOMAINS.secret = "wbbash/allowed_domains";
      ADMIN_EMAILS.secret = "wbbash/admin_emails";
      APP_NAME.secret = "wbbash/miniqdb_name";
      BASE_URL.secret = "wbbash/base_url";
      SMTP_HOST.secret = "wbbash/email_server_host";
      SMTP_PORT.secret = "wbbash/email_server_port";
      SMTP_USERNAME.secret = "wbbash/email_server_user";
      SMTP_PASSWORD.secret = "wbbash/email_server_password";
      SMTP_SENDER_ADDRESS.secret = "wbbash/email_from";
      SMTP_TLS = "true";
      SMTP_SENDER_NAME = "wbbash";
    };
  };
}
