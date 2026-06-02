{ config, ... }:
{
  services.nginx = {
    enable = true;
    virtualHosts.webfinger = {
      listen = [
        {
          addr = "127.0.0.1";
          port = config.k.ports.webfinger_http;
        }
      ];
      locations."= /.well-known/webfinger".extraConfig = ''
        default_type application/jrd+json;
        add_header Access-Control-Allow-Origin "*";
        return 200 '{"subject":"acct:me@kilko.de","links":[{"rel":"http://openid.net/specs/connect/1.0/issuer","href":"https://auth.kilko.de"}]}';
      '';
    };
  };
}
