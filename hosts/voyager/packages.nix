{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    exercism
    exiftool
    ffmpeg_7
    gobuster
    imagemagick
    subfinder
  ];
}
