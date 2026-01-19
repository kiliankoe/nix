{ pkgs, lib, ... }:
let
  dockerService = import ../lib/docker-service.nix { inherit pkgs lib; };
in
dockerService.mkDockerComposeService {
  serviceName = "watchtower";
  monitoring.enable = false;
  auto_update = true;
  compose = {
    services.watchtower = {
      image = "nicholas-fedor/watchtower";
      container_name = "watchtower";
      restart = "unless-stopped";
      volumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
      command = "--label-enable --interval 21600"; # 6 hours
    };
  };
}
