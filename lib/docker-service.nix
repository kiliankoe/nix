{ pkgs }:

{
  # Creates a standardized Docker Compose service
  # serviceName: Name of the service
  # composeFile: The compose file content (pkgs.writeText result)
  # extraFiles: Optional attrset of additional files to copy if necessary
  # environment: Optional attrset of service-scoped environment variables and secrets
  #   Format: { serviceName = { VAR = value; SECRET = { secretFile = "/path"; }; }; _all = { ... }; }
  mkDockerComposeService =
    {
      serviceName,
      composeFile,
      extraFiles ? { },
      environment ? { },
    }:
    let
      serviceDir = "/etc/docker-compose/${serviceName}";
      
      # Helper to create environment file content for a service
      mkEnvFileContent = envVars: 
        builtins.concatStringsSep "\n" (
          builtins.attrValues (
            builtins.mapAttrs (name: value:
              if builtins.isAttrs value && value ? secretFile then
                "${name}=$(cat ${value.secretFile})"
              else
                "${name}=${toString value}"
            ) envVars
          )
        );
      
      # Create environment file scripts for each service
      envScripts = builtins.mapAttrs (svcName: envVars:
        pkgs.writeScript "${serviceName}-${svcName}-env" ''
          #!/bin/sh
          ${mkEnvFileContent envVars}
        ''
      ) environment;
      
      # Generate ExecStartPre commands to create .env files
      envFileCommands = builtins.attrValues (
        builtins.mapAttrs (svcName: script:
          "${script} > ${serviceDir}/${svcName}.env"
        ) envScripts
      );
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
          ExecStartPre = if envFileCommands != [] then envFileCommands else null;
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
