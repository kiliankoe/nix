{ pkgs, lib }:

let
  yamlFormat = pkgs.formats.yaml { };

  defaultBackupConfig = {
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
  # compose: Attrset representing the docker-compose.yml structure
  # extraFiles: Optional attrset of additional files to copy
  # environment: Optional attrset of service-scoped environment variables and secrets
  #   Format: { serviceName = { VAR = value; SECRET = { secretFile = "/path"; }; }; }
  # volumesToBackup: Optional list of volume names to backup with docker-volume-backup
  # backupConfig: Optional override for backup configuration
  mkDockerComposeService =
    {
      serviceName,
      compose,
      extraFiles ? { },
      environment ? { },
      volumesToBackup ? [ ],
      backupConfig ? defaultBackupConfig,
    }:
    let
      serviceDir = "/etc/docker-compose/${serviceName}";

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
        builtins.mapAttrs (
          svcName: script: "${pkgs.bash}/bin/bash -c '${script} > ${serviceDir}/${svcName}.env'"
        ) envScripts
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

      # Backup service definition
      backupService =
        if volumesToBackup != [ ] then
          {
            services.backup = {
              image = "offen/docker-volume-backup:v2";
              restart = "always";
              env_file = [ "./backup.env" ];
              volumes = [
                "/home/kilian/.ssh/id_ed25519:/root/.ssh/id_ed25519:ro"
                "/var/run/docker.sock:/var/run/docker.sock:ro"
              ] ++ map (vol: "${vol}:/backup/${vol}:ro") volumesToBackup;
            };
          }
        else
          { };

      # Merge compose config with backup service
      finalCompose = lib.recursiveUpdate compose backupService;
      composeFile = yamlFormat.generate "${serviceName}-compose.yml" finalCompose;
    in
    {
      # Copy compose files to system
      environment.etc =
        {
          "docker-compose/${serviceName}/docker-compose.yml".source = composeFile;
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
