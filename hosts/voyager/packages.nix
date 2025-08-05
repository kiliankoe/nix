{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    exercism
    ffmpeg_7
    gobuster
    imagemagick
    subfinder
  ];
}
