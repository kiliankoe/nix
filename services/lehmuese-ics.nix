{ config, pkgs, lib, ... }:
let
  dockerService = import ../lib/docker-service.nix { inherit pkgs lib; };
in
dockerService.mkDockerComposeService {
  serviceName = "lehmuese-ics";
  compose = {
    services.lehmuese-ics = {
      container_name = "lehmuese-ics";
      image = "ghcr.io/kiliankoe/lehmuese-ics:1d19a6d9b42e25ef85e9b36c7a70905974d9e614";
      restart = "unless-stopped";
      env_file = [ "lehmuese-ics.env" ];
      volumes = [ "lehmuese-ics-db:/app/db.sqlite" ];
      ports = [ "${toString config.k.ports.lehmuese-ics_http}:3000" ];
    };
    volumes.lehmuese-ics-db = { };
  };
  environment = {
    lehmuese-ics = {
      URL = {
        secretFile = config.sops.secrets."lehmuese_ics/url".path;
      };
    };
  };
}
