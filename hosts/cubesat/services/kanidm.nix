# Kanidm OIDC IdP at auth.kilko.de. Traefik/pangolin fronts the public hostname and proxies to
# the loopback HTTPS bind below (kanidm refuses to serve plain HTTP, so the hop is TLS with a
# self-signed cert, verify off)
#
# domain (WebAuthn RP ID / SPN suffix) is deliberately the apex kilko.de:
# passkeys stay valid if the IdP UI ever moves subdomains, and SPNs read kilian@kilko.de. Changing
# domain later invalidates all enrolled credentials – treat it as write-once.
#
# Provisioning is authoritative (autoRemove): persons/groups/oauth2 clients not declared here
# (or in nix-private's cubesat module) are deleted on activation. Friend accounts and clients
# of private services live in nix-private; public clients live here.
#
# Upgrade path is strict: never skip kanidm minor versions when bumping the package pin
# (1.11 -> 1.12 -> ...).
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
  # Generate a self-signed cert for the loopback TLS bind, once. Runs before kanidm
  systemd.services.kanidm-selfsigned = {
    description = "Generate a self-signed TLS cert for kanidm";
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
    package = pkgs.kanidm_1_11.withSecretProvisioning;

    server = {
      enable = true;
      settings = {
        domain = "kilko.de";
        origin = "https://auth.kilko.de";
        bindaddress = "127.0.0.1:${toString config.k.ports.kanidm_https}";
        tls_chain = tlsCert;
        tls_key = tlsKey;
        # Behind traefik on loopback; trust X-Forwarded-For from that hop only.
        http_client_address_info."x-forward-for" = [ "127.0.0.1" ];
        # 02:00 backups land before the 03:00 restic run picks up the dir.
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
      # defaults true (instanceUrl defaults to https://localhost:<port>), but set
      # it explicitly so it does not silently break if bindaddress changes.
      acceptInvalidCerts = true;
      adminPasswordFile = config.sops.secrets."kanidm/admin_password".path;
      idmAdminPasswordFile = config.sops.secrets."kanidm/idm_admin_password".path;
      # Authoritative: anything not declared is removed from kanidm.
      autoRemove = true;

      persons.kilian = {
        displayName = "Kilian";
        mailAddresses = [ "me@kilko.de" ];
        groups = [
          "pangolin.access"
          "pangolin.admins"
          "grafana.access"
        ];
      };

      groups."pangolin.admins" = { };
      groups."grafana.access" = { };

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

      groups."pangolin.access" = { };

      systems.oauth2.pangolin = {
        displayName = "Pangolin";
        # Callback of the OAuth2/OIDC IdP (id 1) in pangolin's server admin.
        originUrl = "https://tunnel.kilko.de/auth/idp/1/oidc/callback";
        originLanding = "https://tunnel.kilko.de/";
        basicSecretFile = config.sops.secrets."kanidm/oauth2/pangolin_secret".path;
        # role mapping keys on it.
        scopeMaps."pangolin.access" = [
          "openid"
          "profile"
          "email"
          "groups"
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
    "kanidm/oauth2/grafana_secret" = {
      owner = "kanidm";
    };
    "kanidm/oauth2/pangolin_secret" = {
      owner = "kanidm";
    };
  };
}
