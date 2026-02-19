# Periodic Docker cleanup to reclaim disk space from unused images,
# stopped containers, and unused networks. Named volumes are preserved.
{ pkgs, ... }:
{
  systemd.services.docker-prune = {
    description = "Docker system prune";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.docker}/bin/docker system prune -af --volumes";
    };
  };

  systemd.timers.docker-prune = {
    description = "Weekly Docker system prune";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = "Sun 03:00";
      RandomizedDelaySec = "1h";
      Persistent = true;
    };
  };
}
