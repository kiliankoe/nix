{
  config,
  pkgs,
  lib,
  ...
}:
let
  dockerService = import ../../../../lib/docker-service.nix { inherit pkgs lib; };
in
lib.mkMerge [
  (dockerService.mkDockerComposeService {
    serviceName = "lehmuese";
    # Paused during the frood migration, remove this line after to re-enable.
    # Also remove the lib.mkMerge wrapper around the entire service with the
    # `systemd.services.lehmuese.wantedBy = lib.mkForce [ ];` at the bottom.
    monitoring.enable = false;
    auto_update = true;
    backupVolumes = [ "lehmuese-data" ];
    monitoring.httpEndpoint = {
      name = "lehmuese";
      url = "http://localhost:${toString config.k.ports.lehmuese_http}/";
    };
    compose = {
      services.backend = {
        image = "ghcr.io/kiliankoe/wandelmuese/backend:main";
        container_name = "lehmuese-backend";
        restart = "unless-stopped";
        volumes = [ "lehmuese-data:/app/data" ];
        environment = [
          "DATABASE_URL=sqlite:/app/data/lehmuese.db?mode=rwc"
        ];
        env_file = [ "backend.env" ];
      };
      services.frontend = {
        image = "ghcr.io/kiliankoe/wandelmuese/frontend:main";
        container_name = "lehmuese-frontend";
        restart = "unless-stopped";
        ports = [ "${toString config.k.ports.lehmuese_http}:80" ];
        depends_on.backend.condition = "service_started";
      };
      volumes.lehmuese-data = { };
    };
    environment = {
      backend = {
        ENCRYPTION_KEY.secret = "lehmuese/encryption_key";
        ADMIN_EMAILS.secret = "lehmuese/admin_emails";
        SLACK_BOT_TOKEN.secret = "lehmuese/slack_bot_token";
        CORS_ALLOWED_ORIGINS = "https://wandelmuese.dresden.lol";
      };
    };
  })
  {
    systemd.services.lehmuese.wantedBy = lib.mkForce [ ];
  }
]
