{ config, ... }:
{
  virtualisation.oci-containers = {
    backend = "podman";
    containers.linkding = {
      image = "sissbruecker/linkding:latest-plus";
      autoStart = true;
      ports = [
        "${toString config.k.ports.linkding_http}:9090"
      ];
      volumes = [
        "linkding-data:/etc/linkding/data"
      ];
      environment = {
        LD_CONTAINER_NAME = "linkding";
        LD_HOST_PORT = "9090";
        LD_HOST_DATA_DIR = "./data";
        LD_DISABLE_BACKGROUND_TASKS = "False";
        LD_DISABLE_URL_VALIDATION = "False";
      };
      environmentFiles = [
        config.sops.templates."linkding-env".path
      ];
    };
  };

  sops.templates."linkding-env" = {
    content = ''
      LD_SUPERUSER_NAME=${config.sops.placeholder."linkding/superuser_name"}
      LD_SUPERUSER_PASSWORD=${config.sops.placeholder."linkding/superuser_password"}
    '';
  };
}
