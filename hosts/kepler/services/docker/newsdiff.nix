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
  serviceName = "newsdiff";
  auto_update = true;
  backupVolumes = [ "newsdiff-data" ];
  compose = {
    services.backend = {
      container_name = "newsdiff-backend";
      image = "ghcr.io/kiliankoe/news.dresden.lol/backend:main";
      restart = "unless-stopped";
      volumes = [ "newsdiff-data:/app/data" ];
    };
    services.frontend = {
      container_name = "newsdiff-frontend";
      image = "ghcr.io/kiliankoe/news.dresden.lol/frontend:main";
      restart = "unless-stopped";
      ports = [ "${toString config.k.ports.newsdiff_http}:80" ];
    };
    volumes.newsdiff-data = { };
  };
}
