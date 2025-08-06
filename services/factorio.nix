{ config, pkgs, ... }:
let
  dockerService = import ../lib/docker-service.nix { inherit pkgs; };

  composeFile = pkgs.writeText "factorio-compose.yml" ''
    services:
      factorio:
        image: factoriotools/factorio:stable
        container_name: factorio
        restart: unless-stopped
        security_opt:
          - "no-new-privileges:true"
        ports:
          - "34197:34197/udp"
        volumes:
          - factorio-data:/factorio
        environment:
          - GENERATE_NEW_SAVE=true
          - SAVE_NAME=Benjamilius
          - DLC_SPACE_AGE=true

    volumes:
      factorio-data:
  '';
in
dockerService.mkDockerComposeService {
  serviceName = "factorio";
  composeFile = composeFile;
}
