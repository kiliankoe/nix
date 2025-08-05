{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
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
