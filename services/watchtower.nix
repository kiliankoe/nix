{ config, pkgs, ... }:
let
  dockerService = import ../lib/docker-service.nix { inherit pkgs; };

  composeFile = pkgs.writeText "watchtower-compose.yml" ''
    services:
      watchtower:
        image: containrrr/watchtower
        container_name: watchtower
        restart: unless-stopped
        volumes:
          - /var/run/docker.sock:/var/run/docker.sock
        command: --label-enable --interval 21600 # seconds -> 6 hours

    # Use this to enable watchtower for specific containers
    # labels:
    #   - "com.centurylinklabs.watchtower.enable=true"
  '';
in
dockerService.mkDockerComposeService {
  serviceName = "watchtower";
  composeFile = composeFile;
}
