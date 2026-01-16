{ pkgs, lib, ... }:
let
  dockerService = import ../lib/docker-service.nix { inherit pkgs lib; };
in
dockerService.mkDockerComposeService {
  serviceName = "watchtower";
  monitoring.enable = false;
  # To enable watchtower for containers, use: auto_update = true;
  compose = {
    services.watchtower = {
      image = "nickfedor/watchtower";
      container_name = "watchtower";
      restart = "unless-stopped";
      volumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
      command = "--label-enable --interval 21600"; # 6 hours
    };
  };
}
