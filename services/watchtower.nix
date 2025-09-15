{ ... }:
{
  virtualisation.oci-containers = {
    backend = "podman";
    containers.watchtower = {
      image = "containrrr/watchtower";
      autoStart = true;
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
      ];
      cmd = [
        "--label-enable"
        "--interval"
        "21600"
      ];
    };
  };
}

# Use this label to enable watchtower for specific containers
# com.centurylinklabs.watchtower.enable=true
