{
  config,
  lib,
  pkgs,
  ...
}:
let
  dataDir = "/var/lib/pangolin";
  geoipDir = "/var/lib/GeoIP";
in
{
  sops.secrets = {
    "pangolin/server_secret" = { };
    "pangolin/smtp_host" = { };
    "pangolin/smtp_user" = { };
    "pangolin/smtp_pass" = { };
    "pangolin/no_reply" = { };
    "maxmind/license_key" = { };
  };


  services.geoipupdate = {
    enable = true;
    interval = "weekly";
    settings = {
      AccountID = 1281177;
      LicenseKey = {
        _secret = config.sops.secrets."maxmind/license_key".path;
      };
      EditionIDs = [ "GeoLite2-Country" ];
      DatabaseDirectory = geoipDir;
    };
  };

  systemd.services.pangolin-geoip-link = {
    description = "Link GeoIP database for Pangolin";
    wantedBy = [ "pangolin.service" ];
    before = [ "pangolin.service" ];
    after = [ "geoipupdate.service" ];
    requires = [ "geoipupdate.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      set -euo pipefail
      test -s ${geoipDir}/GeoLite2-Country.mmdb
      mkdir -p ${dataDir}/config
      ln -sf ${geoipDir}/GeoLite2-Country.mmdb ${dataDir}/config/GeoLite2-Country.mmdb
    '';
  };

  services.pangolin = {
    enable = true;
    baseDomain = "gptdash.de";
    dashboardDomain = "tunnel.gptdash.de";
    letsEncryptEmail = "me@kilian.io";
    inherit dataDir;
    openFirewall = true;
    environmentFile = "/dev/null";

    settings = {
      app = {
        dashboard_url = "https://tunnel.gptdash.de";
        log_level = "info";
      };

      domains.domain1 = {
        base_domain = "gptdash.de";
        cert_resolver = "letsencrypt";
      };

      server = {
        secret = "@SERVER_SECRET@";
        cors = {
          origins = [ "https://tunnel.gptdash.de" ];
          methods = [
            "GET"
            "POST"
            "PUT"
            "DELETE"
            "PATCH"
          ];
          allowed_headers = [
            "X-CSRF-Token"
            "Content-Type"
          ];
          credentials = false;
        };
        maxmind_db_path = "${dataDir}/config/GeoLite2-Country.mmdb";
      };

      gerbil = {
        start_port = 51820;
        base_endpoint = "tunnel.gptdash.de";
      };

      email = {
        smtp_host = "@SMTP_HOST@";
        smtp_port = 465;
        smtp_secure = true;
        smtp_user = "@SMTP_USER@";
        smtp_pass = "@SMTP_PASS@";
        no_reply = "@NO_REPLY@";
      };

      flags = {
        require_email_verification = false;
        disable_signup_without_invite = true;
        disable_user_create_org = false;
        allow_raw_resources = true;
        allow_base_domain_resources = true;
      };
    };
  };

  systemd.services.pangolin = {
    after = [ "pangolin-geoip-link.service" ];
    requires = [ "pangolin-geoip-link.service" ];
    preStart = lib.mkAfter ''
      ${pkgs.gnused}/bin/sed -i \
        -e "s|@SERVER_SECRET@|$(cat ${config.sops.secrets."pangolin/server_secret".path})|" \
        -e "s|@SMTP_HOST@|$(cat ${config.sops.secrets."pangolin/smtp_host".path})|" \
        -e "s|@SMTP_USER@|$(cat ${config.sops.secrets."pangolin/smtp_user".path})|" \
        -e "s|@SMTP_PASS@|$(cat ${config.sops.secrets."pangolin/smtp_pass".path})|" \
        -e "s|@NO_REPLY@|$(cat ${config.sops.secrets."pangolin/no_reply".path})|" \
        ${dataDir}/config/config.yml
    '';
  };

  # CrowdSec is disabled for initial deployment due to NixOS module issues.
  # TODO: Enable once NixOS crowdsec modules are more stable.
  # See: https://github.com/NixOS/nixpkgs/issues/445342
  #
  # To enable later:
  # services.crowdsec = {
  #   enable = true;
  #   settings.general.api.server.enable = true;
  #   localConfig.acquisitions = [{
  #     filenames = [ "${dataDir}/logs/traefik/*.log" ];
  #     labels.type = "traefik";
  #   }];
  #   hub.collections = [ "crowdsecurity/traefik" "crowdsecurity/linux" ];
  # };
  # services.crowdsec-firewall-bouncer = {
  #   enable = true;
  #   settings.api_url = "http://localhost:8080";
  # };

}
