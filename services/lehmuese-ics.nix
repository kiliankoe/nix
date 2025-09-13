{ config, pkgs, ... }:
let
  dockerService = import ../lib/docker-service.nix { inherit pkgs; };

  composeFile = pkgs.writeText "lehmuese-ics-compose.yml" ''
    services:
      lehmuese-ics:
        container_name: lehmuese-ics
        image: ghcr.io/kiliankoe/lehmuese-ics:latest
        restart: unless-stopped
        env_file:
          - lehmuese-ics.env
        volumes:
          - lehmuese-ics-db:/app/db.sqlite
        ports:
          - '${toString config.k.ports.lehmuese-ics_http}:3000'

    volumes:
      lehmuese-ics-db:
  '';
in
dockerService.mkDockerComposeService {
  serviceName = "lehmuese-ics";
  composeFile = composeFile;
  environment = {
    lehmuese-ics = {
      URL = {
        secretFile = config.sops.secrets."lehmuese_ics/url".path;
      };
    };
  };
}
