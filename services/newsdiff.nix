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
  serviceName = "newsdiff";
  compose = {
    services.backend = {
      image = "ghcr.io/kiliankoe/news.dresden.lol/backend:main";
      restart = "unless-stopped";
      volumes = [ "newsdiff-data:/data" ];
      labels = [ "com.centurylinklabs.watchtower.enable=true" ];
    };
    services.frontend = {
      image = "ghcr.io/kiliankoe/news.dresden.lol/frontend:main";
      restart = "unless-stopped";
      ports = [ "${toString config.k.ports.newsdiff_http}:80" ];
      labels = [ "com.centurylinklabs.watchtower.enable=true" ];
    };
    volumes.newsdiff-data = { };
  };
}
