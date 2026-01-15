{
  config,
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

  systemd.services.pangolin-env = {
    description = "Generate Pangolin environment file";
    wantedBy = [ "pangolin.service" ];
    before = [ "pangolin.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -euo pipefail
      mkdir -p /run/pangolin
      test -s ${config.sops.secrets."pangolin/server_secret".path}
      test -s ${config.sops.secrets."pangolin/smtp_host".path}
      test -s ${config.sops.secrets."pangolin/smtp_user".path}
      test -s ${config.sops.secrets."pangolin/smtp_pass".path}
      test -s ${config.sops.secrets."pangolin/no_reply".path}
      cat > /run/pangolin/env <<EOF
      SERVER_SECRET=$(cat ${config.sops.secrets."pangolin/server_secret".path})
      EMAIL_SMTP_HOST=$(cat ${config.sops.secrets."pangolin/smtp_host".path})
      EMAIL_SMTP_USER=$(cat ${config.sops.secrets."pangolin/smtp_user".path})
      EMAIL_SMTP_PASS=$(cat ${config.sops.secrets."pangolin/smtp_pass".path})
      EMAIL_NO_REPLY=$(cat ${config.sops.secrets."pangolin/no_reply".path})
      EOF
      chmod 600 /run/pangolin/env
    '';
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
    baseDomain = "kilko.de";
    dashboardDomain = "tunnel.kilko.de";
    letsEncryptEmail = "me@kilian.io";
    inherit dataDir;
    openFirewall = true;
    environmentFile = "/run/pangolin/env";

    settings = {
      app = {
        dashboard_url = "https://tunnel.kilko.de";
        log_level = "info";
      };

      domains.domain1 = {
        base_domain = "kilko.de";
        cert_resolver = "letsencrypt";
      };

      server = {
        cors = {
          origins = [ "https://tunnel.kilko.de" ];
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
        base_endpoint = "tunnel.kilko.de";
      };

      email = {
        smtp_port = 465;
        smtp_secure = true;
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
