{ pkgs }:

{
  # Creates a standardized Docker Compose service
  # serviceName: Name of the service
  # composeFile: The compose file content (pkgs.writeText result)
  # extraFiles: Optional attrset of additional files to copy if necessary
  mkDockerComposeService =
    {
      serviceName,
      composeFile,
      extraFiles ? { },
    }:
    let
      serviceDir = "/etc/docker-compose/${serviceName}";
    in
    {
      # Copy compose files to system
      environment.etc = {
        "docker-compose/${serviceName}/docker-compose.yml".source = composeFile;
      }
      // extraFiles;

      systemd.services.${serviceName} = {
        description = "Docker Compose service for ${serviceName}";
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          WorkingDirectory = serviceDir;
          ExecStart = "${pkgs.docker-compose}/bin/docker-compose up -d";
          ExecStop = "${pkgs.docker-compose}/bin/docker-compose down";
          ExecReload = "${pkgs.docker-compose}/bin/docker-compose up -d --force-recreate";
          TimeoutStartSec = 0;
          User = "root";
        };

        unitConfig = {
          StartLimitBurst = 3;
          StartLimitIntervalSec = 60;
        };
      };

      systemd.tmpfiles.rules = [
        "d ${serviceDir} 0755 root root -"
      ];
    };
}
