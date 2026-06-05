{
  config,
  pkgs,
  lib,
  ...
}:
let
  dockerService = import ../../../../lib/docker-service.nix { inherit pkgs lib; };
in
lib.mkMerge [
  (dockerService.mkDockerComposeService {
    serviceName = "watchstate";
    auto_update = false;
    backupVolumes = [ "watchstate-config" ];
    monitoring.httpEndpoint = {
      name = "watchstate";
      url = "http://127.0.0.1:${toString config.k.ports.watchstate_http}/";
    };
    compose = {
      services.watchstate = {
        container_name = "watchstate";
        image = "ghcr.io/arabcoders/watchstate:latest@sha256:124f4ceaf2a8f098d1dd9b027b12664a7ff1e712e273e11ee8d98365b4a2f7b4";
        # watchstate runs rootless; pinning the uid keeps the docker volume's
        # ownership deterministic across image rebuilds.
        user = "1000:1000";
        restart = "unless-stopped";
        environment = [
          "TZ=${config.time.timeZone}"
          "WS_TRUST_PROXY=false"
        ];
        volumes = [ "watchstate-config:/config" ];
        ports = [ "${toString config.k.ports.watchstate_http}:8080" ];
        # Resolve host.docker.internal to the host's bridge IP so watchstate
        # can reach kepler's host services (jellyfin via the nginx proxy on
        # config.k.ports.jellyfin_http) from inside the container.
        extra_hosts = [ "host.docker.internal:host-gateway" ];
      };
      volumes.watchstate-config = { };
    };
  })
  {
    networking.firewall.allowedTCPPorts = [ config.k.ports.watchstate_http ];
  }
]
