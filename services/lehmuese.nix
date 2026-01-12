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
  serviceName = "lehmuese";
  compose = {
    services.backend = {
      image = "ghcr.io/kiliankoe/lehmuese/backend:main";
      container_name = "lehmuese-backend";
      restart = "unless-stopped";
      volumes = [ "lehmuese-data:/app/data" ];
      environment = [
        "DATABASE_URL=sqlite:/app/data/lehmuese.db?mode=rwc"
      ];
      env_file = [ "backend.env" ];
      labels = [ "com.centurylinklabs.watchtower.enable=true" ];
    };
    services.frontend = {
      image = "ghcr.io/kiliankoe/lehmuese/frontend:main";
      container_name = "lehmuese-frontend";
      restart = "unless-stopped";
      ports = [ "${toString config.k.ports.lehmuese_http}:80" ];
      depends_on.backend.condition = "service_started";
      labels = [ "com.centurylinklabs.watchtower.enable=true" ];
    };
    volumes.lehmuese-data = { };
  };
  environment = {
    backend = {
      ENCRYPTION_KEY.secret = "lehmuese/encryption_key";
    };
  };
}
