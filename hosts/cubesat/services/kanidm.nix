{
  config,
  pkgs,
  ...
}:
let
  dataDir = "/var/lib/kanidm";
  tlsCert = "${dataDir}/self-signed.crt";
  tlsKey = "${dataDir}/self-signed.key";
in
{
  # Generate a self-signed cert for the loopback TLS bind, once. Runs before kanidm.
  systemd.services.kanidm-selfsigned = {
    description = "Generate self-signed TLS cert for kanidm";
    wantedBy = [ "kanidm.service" ];
    before = [ "kanidm.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "kanidm";
      Group = "kanidm";
      StateDirectory = "kanidm";
      StateDirectoryMode = "0700";
      UMask = "0077";
    };
    script = ''
      if [ ! -f ${tlsCert} ] || [ ! -f ${tlsKey} ]; then
        ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:2048 -nodes \
          -keyout ${tlsKey} -out ${tlsCert} -days 3650 \
          -subj "/CN=auth.kilko.de" \
          -addext "subjectAltName=DNS:auth.kilko.de"
      fi
    '';
  };

  services.kanidm = {
    package = pkgs.kanidm_1_10.withSecretProvisioning;

    server = {
      enable = true;
      settings = {
        domain = "auth.kilko.de";
        origin = "https://auth.kilko.de";
        bindaddress = "127.0.0.1:${toString config.k.ports.kanidm_https}";
        tls_chain = tlsCert;
        tls_key = tlsKey;
        # Behind Traefik/Pangolin; trust the forwarded client address.
        trust_x_forward_for = true;
        online_backup = {
          versions = 7;
          schedule = "00 02 * * *";
        };
      };
    };

    client = {
      enable = true;
      settings.uri = "https://auth.kilko.de";
    };

    provision = {
      enable = true;
      # Provisioning connects to the self-signed loopback endpoint. This already
      # defaults true (instanceUrl defaults to https://localhost:<port>), but set it
      # explicitly so it does not silently break if bindaddress changes.
      acceptInvalidCerts = true;
      adminPasswordFile = config.sops.secrets."kanidm/admin_password".path;
      idmAdminPasswordFile = config.sops.secrets."kanidm/idm_admin_password".path;
      # Authoritative: anything not declared here is removed from kanidm.
      autoRemove = true;

      persons.kilian = {
        displayName = "Kilian";
        mailAddresses = [ "me@kilko.de" ];
        groups = [
          "tailscale.access"
          "grafana.access"
        ];
      };

      groups."tailscale.access" = { };
      groups."grafana.access" = { };

      systems.oauth2.tailscale = {
        displayName = "Tailscale";
        originUrl = "https://login.tailscale.com/a/oauth_response";
        originLanding = "https://login.tailscale.com/";
        basicSecretFile = config.sops.secrets."kanidm/oauth2/tailscale_secret".path;
        scopeMaps."tailscale.access" = [
          "openid"
          "email"
          "profile"
        ];
        preferShortUsername = true;
      };

      systems.oauth2.grafana = {
        displayName = "Grafana";
        originUrl = "https://grafana.kilko.de/login/generic_oauth";
        originLanding = "https://grafana.kilko.de/";
        basicSecretFile = config.sops.secrets."kanidm/oauth2/grafana_secret".path;
        scopeMaps."grafana.access" = [
          "openid"
          "email"
          "profile"
        ];
        preferShortUsername = true;
      };
    };
  };

  sops.secrets = {
    "kanidm/admin_password" = {
      owner = "kanidm";
    };
    "kanidm/idm_admin_password" = {
      owner = "kanidm";
    };
    "kanidm/oauth2/tailscale_secret" = {
      owner = "kanidm";
    };
    "kanidm/oauth2/grafana_secret" = {
      owner = "kanidm";
    };
  };
}
