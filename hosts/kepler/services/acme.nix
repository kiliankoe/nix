# Wildcard TLS for the split-horizon local proxy (vhosts live in nix-private): home-LAN clients
# resolve service hostnames to kepler via UniFi local DNS records and get TLS here, bypassing the
# Pangolin path entirely.
#
# Deliberately one wildcard cert, not per-host certs, so service hostnames don't appear in cert
# transparency records. dnsResolver forces lego's propagation preflight through a public resolver –
# with split-horizon DNS the local resolver would answer for kilko.de names and confuse it.
{ config, pkgs, ... }:
{
  sops.secrets."hetzner/api_token" = { };

  security.acme = {
    acceptTerms = true;
    defaults.email = "me@kilian.io";
    certs."kilko.de" = {
      domain = "kilko.de";
      extraDomainNames = [ "*.kilko.de" ];
      dnsProvider = "hetzner";
      credentialFiles."HETZNER_API_TOKEN_FILE" = config.sops.secrets."hetzner/api_token".path;
      dnsResolver = "1.1.1.1:53";
      # Hetzner's NS fleet syncs slowly; the provider default (60s) submits before all vantage
      # points see the TXT records and LE's secondary validation then fails. Poll patiently
      # before letting LE validate.
      environmentFile = pkgs.writeText "acme-hetzner-tuning" ''
        HETZNER_PROPAGATION_TIMEOUT=600
        HETZNER_POLLING_INTERVAL=10
      '';
      group = "nginx";
    };
  };

  # Default server for both ports: any hostname without an explicit vhost (or a bare-IP scan of
  # kepler:443) gets the connection closed instead of a cert and a service.
  services.nginx = {
    enable = true;
    virtualHosts."catchall" = {
      default = true;
      addSSL = true;
      useACMEHost = "kilko.de";
      extraConfig = "return 444;";
    };
  };

  networking.firewall.allowedTCPPorts = [
    80 # http -> https redirects only (forceSSL vhosts)
    443
  ];
}
