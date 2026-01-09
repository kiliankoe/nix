# Monitoring stack for kepler
# Prometheus + Grafana + AlertManager + exporters
#
# Access points:
#   - Grafana:      http://kepler:8394 (dashboards, visualization)
#   - Prometheus:   http://kepler:8393 (metrics, targets, rules)
#   - AlertManager: http://kepler:8395 (alert management)
#
# Secrets required in secrets/secrets.yaml:
#   monitoring/grafana_admin_password
#   monitoring/smtp_host
#   monitoring/smtp_username
#   monitoring/smtp_password
#   monitoring/alert_email_to
#   monitoring/alert_email_from
{ config, ... }:
{
  imports = [
    ./exporters.nix
    ./prometheus.nix
    ./alertmanager.nix
    ./grafana.nix
    ./cadvisor.nix
  ];

  # Open firewall for external access to dashboards
  # Prometheus and AlertManager are also exposed for debugging
  networking.firewall.allowedTCPPorts = [
    config.k.ports.grafana_http
    config.k.ports.prometheus_http
    config.k.ports.alertmanager_http
  ];
}
