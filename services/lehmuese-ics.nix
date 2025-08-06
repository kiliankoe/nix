{ config, pkgs, ... }:
let
  dockerService = import ../lib/docker-service.nix { inherit pkgs; };

  composeFile = pkgs.writeText "lehmuese-ics-compose.yml" ''
    services:
      lehmuese-ics:
        container_name: lehmuese-ics
        image: lehmuese-ics:latest # TODO: Publish on ghcr.io
        restart: unless-stopped
        environment:
          - URL=${builtins.readFile config.sops.secrets."lehmuese_ics/url".path}
        volumes:
          - lehmuese-ics-db:/app/db.sqlite
        ports:
          - '8380:3000'

    volumes:
      lehmuese-ics-db:
  '';
in
dockerService.mkDockerComposeService {
  serviceName = "lehmuese-ics";
  composeFile = composeFile;
}
