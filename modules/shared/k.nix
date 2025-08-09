{ lib, ... }:
{
  options.k = {
    ports = lib.mkOption {
      type = lib.types.attrsOf lib.types.int;
      default = {
        changedetection_http = 8380;
        factorio_udp = 34197;
        forgejo_http = 8381;
        forgejo_ssh = 10022;
        freshrss_http = 8382;
        linkding_http = 8383;
        mato_http = 8384;
        paperless_http = 8385;
        rssbridge_http = 8386;
        uptime_kuma_http = 8387;
        wbbash_http = 8388;
      };
      description = ''
        Central registry for service port assignments to avoid conflicts and
        keep them discoverable.
      '';
    };
  };
}
