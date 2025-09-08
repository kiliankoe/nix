{ pkgs }:

let
  backupConfig = {
    sshHost = "marvin";
    sshPort = 43593;
    sshUser = "kilian";
    sshBasePath = "/volume1/Backups/kepler";
    schedule = "0 4 * * *"; # Daily at 4 AM
  };
in
{
  # Creates a standardized Docker Compose service
  # serviceName: Name of the service
  # composeFile: The compose file content (pkgs.writeText result)
  # extraFiles: Optional attrset of additional files to copy if necessary
  # environment: Optional attrset of service-scoped environment variables and secrets
  #   Format: { serviceName = { VAR = value; SECRET = { secretFile = "/path"; }; }; _all = { ... }; }
  # volumesToBackup: Optional list of volume names to backup with docker-volume-backup
  mkDockerComposeService =
    {
      serviceName,
      composeFile,
      extraFiles ? { },
      environment ? { },
      volumesToBackup ? [ ],
    }:
    let
      serviceDir = "/etc/docker-compose/${serviceName}";

      # Helper to create environment file content for a service
      mkEnvFileContent =
        envVars:
        builtins.concatStringsSep "\n" (
          builtins.attrValues (
            builtins.mapAttrs (
              name: value:
              if builtins.isAttrs value && value ? secretFile then
                "${name}=$(cat ${value.secretFile})"
              else
                "${name}=${toString value}"
            ) envVars
          )
        );

      # Create environment file scripts for each service
      envScripts = builtins.mapAttrs (
        svcName: envVars:
        pkgs.writeScript "${serviceName}-${svcName}-env" ''
          #!/bin/sh
          ${builtins.concatStringsSep "\n" (
            builtins.attrValues (
              builtins.mapAttrs (
                name: value:
                if builtins.isAttrs value && value ? secretFile then
                  "echo \"${name}=$(cat ${value.secretFile})\""
                else
                  "echo \"${name}=${toString value}\""
              ) envVars
            )
          )}
        ''
      ) environment;

      # Generate ExecStartPre commands to create .env files
      envFileCommands = builtins.attrValues (
        builtins.mapAttrs (svcName: script: "${script} > ${serviceDir}/${svcName}.env") envScripts
      );

      # Create backup environment file if volumes are specified
      backupEnvFile =
        if volumesToBackup != [ ] then
          pkgs.writeText "${serviceName}-backup.env" ''
            BACKUP_CRON_EXPRESSION=${backupConfig.schedule}
            SSH_HOST_NAME=${backupConfig.sshHost}
            SSH_PORT=${toString backupConfig.sshPort}
            SSH_REMOTE_PATH=${backupConfig.sshBasePath}/${serviceName}
            SSH_USER=${backupConfig.sshUser}
            SSH_IDENTITY_FILE="/root/.ssh/id_ed25519"
          ''
        else
          null;

      # Generate volume mounts for backup service
      backupVolumeMounts = builtins.map (volume: "${volume}:/backup/${volume}:ro") volumesToBackup;

      # Parse the original compose file and inject backup service if needed
      finalComposeFile =
        if volumesToBackup != [ ] then
          pkgs.writeText "${serviceName}-compose-with-backup.yml" (
            builtins.readFile composeFile
            + ''

              backup:
                image: offen/docker-volume-backup:v2
                restart: always
                env_file: ./backup.env
                volumes:
                  - /home/kilian/.ssh/id_ed25519:/root/.ssh/id_ed25519:ro
                  - /var/run/docker.sock:/var/run/docker.sock:ro
                  ${builtins.concatStringsSep "\n          " (
                    builtins.map (mount: "- ${mount}") backupVolumeMounts
                  )}
            ''
          )
        else
          composeFile;
    in
    {
      # Copy compose files to system
      environment.etc = {
        "docker-compose/${serviceName}/docker-compose.yml".source = finalComposeFile;
      }
      // extraFiles
      // (
        if backupEnvFile != null then
          {
            "docker-compose/${serviceName}/backup.env".source = backupEnvFile;
          }
        else
          { }
      );

      systemd.services.${serviceName} = {
        description = "Docker Compose service for ${serviceName}";
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          WorkingDirectory = serviceDir;
          ExecStartPre = if envFileCommands != [ ] then envFileCommands else null;
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
