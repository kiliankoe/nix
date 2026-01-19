{
  pkgs,
  lib,
  config,
  ...
}:
let
  dockerService = import ../lib/docker-service.nix { inherit pkgs lib; };
  serviceDir = "/etc/docker-compose/watchtower";
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
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "${serviceDir}/config.json:/config.json:ro"
      ];
      command = "--label-enable --interval 21600"; # 6 hours
    };
  };
}
// {
  sops.secrets."watchtower/ghcr_auth" = { };

  systemd.services.watchtower = {
    serviceConfig.ExecStartPre = lib.mkBefore [
      (pkgs.writeScript "watchtower-generate-config" ''
        #!${pkgs.bash}/bin/bash
        AUTH=$(cat ${config.sops.secrets."watchtower/ghcr_auth".path})
        cat > ${serviceDir}/config.json <<EOF
        {
          "auths": {
            "ghcr.io": {
              "auth": "$AUTH"
            }
          }
        }
        EOF
        chmod 600 ${serviceDir}/config.json
      '')
    ];
  };
}
