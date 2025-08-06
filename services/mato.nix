{ config, pkgs, ... }:
let
  dockerService = import ../lib/docker-service.nix { inherit pkgs; };

  composeFile = pkgs.writeText "mato-compose.yml" ''
    services:
      app:
        image: ghcr.io/kiliankoe/mato:latest
        restart: unless-stopped
        env_file:
          - .env
        environment:
          - TIMEZONE=Europe/Berlin
          - DB_PATH=/data/db.json
        volumes:
          - mato-data:/data
        ports:
          - '12123:5050'
        healthcheck:
          test:
            - CMD
            - curl
            - '-f'
            - 'http://127.0.0.1:5050/webhook'
          interval: 2s
          timeout: 10s
          retries: 15

    volumes:
      mato-data:
  '';
in
dockerService.mkDockerComposeService {
  serviceName = "mato";
  composeFile = composeFile;
}
