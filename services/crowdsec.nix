{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.crowdsec;
  dataDir = "/var/lib/crowdsec";
  configDir = "/etc/crowdsec";
  cs = pkgs.crowdsec;
  defaultAcquisYaml = pkgs.writeText "acquis.yaml" ''
    filenames:
      - /var/log/auth.log
      - /var/log/secure
      - /var/log/nginx/access.log
      - /var/log/nginx/error.log
    labels:
      type: syslog
  '';
  renderedAcquis = if cfg.acquisFile != null then cfg.acquisFile else defaultAcquisYaml;
  postInstallHub = pkgs.writeShellScript "crowdsec-hub" ''
    set -e
    ${cs}/bin/cscli hub update
    ${cs}/bin/cscli hub install crowdsecurity/linux
    ${cs}/bin/cscli hub install crowdsecurity/sshd
    ${cs}/bin/cscli hub install crowdsecurity/nginx
    ${cs}/bin/cscli hub upgrade
  '';
in
{
  options.services.crowdsec = with lib; {
    enable = mkEnableOption "CrowdSec IDS/IPS";
    enableFirewallBouncer = mkEnableOption "CrowdSec firewall bouncer";
    acquisFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Optional acquis.yaml to override default log acquisition";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # Provide upstream default config files from the package (YAML), and our acquis.yaml
      environment.etc = {
        "crowdsec/config.yaml".source = "${cs}/share/crowdsec/config/config.yaml";
        "crowdsec/profiles.yaml".source = "${cs}/share/crowdsec/config/profiles.yaml";
        "crowdsec/whitelists.yaml".source = "${cs}/share/crowdsec/config/whitelists.yaml";
        "crowdsec/simulation.yaml".source = "${cs}/share/crowdsec/config/simulation.yaml";
        "crowdsec/acquis.yaml".source = renderedAcquis;
      };

      users.users.crowdsec = {
        isSystemUser = true;
        group = "crowdsec";
        home = dataDir;
      };
      users.groups.crowdsec = { };

      systemd.services.crowdsec = {
        description = "Crowdsec agent";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          User = "crowdsec";
          Group = "crowdsec";
          StateDirectory = "crowdsec crowdsec/run crowdsec/log crowdsec/data";
          ExecStartPre = postInstallHub;
          ExecStart = "${cs}/bin/crowdsec -c ${configDir}/config.yaml";
          Restart = "on-failure";
          AmbientCapabilities = "";
          CapabilityBoundingSet = "";
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
        };
      };
    })

    (lib.mkIf cfg.enableFirewallBouncer {
      systemd.services.crowdsec-firewall-bouncer = {
        description = "CrowdSec firewall bouncer";
        after = [ "crowdsec.service" ];
        requires = [ "crowdsec.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          User = "root";
          ExecStart = "${pkgs.crowdsec-firewall-bouncer}/bin/crowdsec-firewall-bouncer";
          Restart = "on-failure";
        };
      };
    })
  ];
}
