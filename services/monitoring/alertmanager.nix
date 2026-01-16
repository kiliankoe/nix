# AlertManager with email notifications
#
# The NixOS AlertManager module processes configText through envsubst,
# but for file-based secrets we need a different approach.
# We use a wrapper service to generate the config at runtime.
{ config, pkgs, ... }:
let
  # Script to generate alertmanager config with secrets at runtime
  alertmanagerConfigScript = pkgs.writeShellScript "alertmanager-config" ''
        set -euo pipefail

        SMTP_HOST=$(cat /run/secrets/monitoring/smtp_host)
        SMTP_USER=$(cat /run/secrets/monitoring/smtp_username)
        SMTP_PASS=$(cat /run/secrets/monitoring/smtp_password)
        EMAIL_TO=$(cat /run/secrets/monitoring/alert_email_to)
        EMAIL_FROM=$(cat /run/secrets/monitoring/alert_email_from)

        mkdir -p /var/lib/alertmanager

        cat > /var/lib/alertmanager/alertmanager.yml << EOF
    global:
      smtp_smarthost: '$SMTP_HOST'
      smtp_from: '$EMAIL_FROM'
      smtp_auth_username: '$SMTP_USER'
      smtp_auth_password: '$SMTP_PASS'
      smtp_require_tls: true

    route:
      receiver: 'email-alerts'
      group_by: ['alertname', 'severity']
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 4h
      routes:
        - match:
            severity: critical
          repeat_interval: 1h
          receiver: 'email-alerts'

    receivers:
      - name: 'email-alerts'
        email_configs:
          - to: '$EMAIL_TO'
            send_resolved: true
            headers:
              Subject: '[kepler] {{ .Status | toUpper }}: {{ .GroupLabels.alertname }}'

    inhibit_rules:
      - source_match:
          severity: 'critical'
        target_match:
          severity: 'warning'
        equal: ['alertname']
    EOF

        chmod 600 /var/lib/alertmanager/alertmanager.yml
  '';
in
{
  # Ensure alertmanager data directory exists
  systemd.tmpfiles.rules = [
    "d /var/lib/alertmanager 0700 root root -"
    "d /var/lib/alertmanager/data 0700 root root -"
  ];

  # Generate config before alertmanager starts
  systemd.services.alertmanager-config = {
    description = "Generate AlertManager config with secrets";
    before = [ "alertmanager.service" ];
    requiredBy = [ "alertmanager.service" ];
    after = [ "sops-nix.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = alertmanagerConfigScript;
      RemainAfterExit = true;
    };
  };

  # Run alertmanager manually since we need custom config path
  systemd.services.alertmanager = {
    description = "Prometheus Alertmanager";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network-online.target"
      "alertmanager-config.service"
    ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      ExecStart = ''
        ${pkgs.prometheus-alertmanager}/bin/alertmanager \
          --config.file=/var/lib/alertmanager/alertmanager.yml \
          --storage.path=/var/lib/alertmanager/data \
          --web.listen-address=0.0.0.0:${toString config.k.ports.alertmanager_http}
      '';
      Restart = "on-failure";
      RestartSec = "5s";
      DynamicUser = false;
      WorkingDirectory = "/var/lib/alertmanager";
    };
  };

  # Declare secrets for alertmanager
  sops.secrets = {
    "monitoring/smtp_host" = { };
    "monitoring/smtp_username" = { };
    "monitoring/smtp_password" = { };
    "monitoring/alert_email_to" = { };
    "monitoring/alert_email_from" = { };
  };
}
