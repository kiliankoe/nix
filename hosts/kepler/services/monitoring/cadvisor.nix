# cAdvisor for Docker container metrics
# Deployed as Docker container using the docker-service helper
{ pkgs, lib, ... }:
let
  dockerService = import ../../../lib/docker-service.nix { inherit pkgs lib; };
in
dockerService.mkDockerComposeService {
  serviceName = "cadvisor";
  monitoring.enable = false;
  compose = {
    services.cadvisor = {
      image = "gcr.io/cadvisor/cadvisor:v0.51.0";
      container_name = "cadvisor";
      privileged = true;
      restart = "unless-stopped";
      ports = [
        # Only expose internally for Prometheus scraping
        "127.0.0.1:8080:8080"
      ];
      volumes = [
        "/:/rootfs:ro"
        "/var/run:/var/run:ro"
        "/sys:/sys:ro"
        "/var/lib/docker/:/var/lib/docker:ro"
        "/dev/disk/:/dev/disk:ro"
      ];
      devices = [
        "/dev/kmsg"
      ];
      # Resource limits to prevent cAdvisor from consuming too much
      deploy = {
        resources = {
          limits = {
            memory = "256M";
            cpus = "0.5";
          };
        };
      };
    };
  };
}
