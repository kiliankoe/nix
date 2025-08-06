{ config, pkgs, ... }:
let
  dockerService = import ../lib/docker-service.nix { inherit pkgs; };

  composeFile = pkgs.writeText "uptime-kuma-compose.yml" ''
    services:
      uptime-kuma:
        image: louislam/uptime-kuma:latest
        container_name: uptime-kuma
        restart: unless-stopped
        security_opt:
          - "no-new-privileges:true"
        volumes:
          - uptime-kuma-data:/app/data
        ports:
          - '8385:3001'

    volumes:
      uptime-kuma-data:
  '';
in
dockerService.mkDockerComposeService {
  serviceName = "uptime-kuma";
  composeFile = composeFile;
}
