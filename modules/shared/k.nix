{ lib, ... }:
{
  options.k = {
    ports = lib.mkOption {
      type = lib.types.attrsOf lib.types.int;
      default = {
        changedetection = 5000;
        forgejo_http = 8378;
        forgejo_ssh = 22222;
        freshrss_http = 8380;
        rssbridge_http = 8384;
        paperless_http = 8382;
        uptime_kuma = 3001;
        factorio_udp = 34197;
        linkding_http = 8381;
        mato_http = 12123;
        wbbash_http = 8386;
      };
      description = ''
        Central registry for service port assignments. Override per-host
        via k.ports.<name> = <port>; to avoid conflicts and keep them discoverable.
      '';
    };
  };
}
