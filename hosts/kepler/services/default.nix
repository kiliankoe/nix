{ ... }:
{
  imports = [
    # Native NixOS services
    ./freshrss.nix
    ./paperless.nix
    ./radarr.nix
    ./sabnzbd.nix
    ./sonarr.nix
    ./uptime-kuma.nix

    # Unified backup for all services
    ./backup.nix

    # Periodic cleanup
    ./docker-prune.nix
    ./nix-gc.nix

    # Monitoring stack (Prometheus + Grafana + AlertManager)
    ./monitoring

    # Docker-based services
    ./docker

  ];
}
