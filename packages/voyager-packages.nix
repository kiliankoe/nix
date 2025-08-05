{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    dedup-darwin
    exercism
    ffmpeg_7
    gobuster
    imagemagick
    lazydocker
    mitmproxy
    mitmproxy2swagger
    nh
    nil
    nixd
    nixpkgs-fmt
    ripgrep-all
    subfinder
  ];
}
