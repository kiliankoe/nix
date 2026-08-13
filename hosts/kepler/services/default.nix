{ ... }:
{
  imports = [
    # Native NixOS services
    ./freshrss.nix
    ./hister.nix
    ./mediawiki-personal.nix
    ./mediawiki-family.nix
    ./paperless.nix

    # Unified backup for all services
    ./backup.nix

    # Periodic cleanup
    ./docker-prune.nix

    # Monitoring stack (Prometheus + Grafana + AlertManager)
    ./monitoring

    # Docker-based services
    ./docker
  ];
}
