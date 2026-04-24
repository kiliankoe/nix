{ pkgs, ... }:
{
  # sublime4 still bundles openssl 1.1, which nixpkgs marks insecure.
  nixpkgs.config.permittedInsecurePackages = [ "openssl-1.1.1w" ];

  environment.systemPackages = with pkgs; [
    _1password-cli
    _1password-gui
    celluloid
    ddcui
    ddcutil
    element-desktop
    filezilla
    firefox
    ghostty
    kdePackages.filelight
    mitmproxy
    mpv
    obsidian
    qalculate-gtk
    rpi-imager
    sublime-merge
    sublime4
    tableplus
    thunderbird
    transmission_4-gtk
    trimage
    yaak
    zed-editor

    # fonts
    nerd-fonts.jetbrains-mono
    nerd-fonts.monaspace
    nerd-fonts.comic-shanns-mono
    open-sans
    inter
  ];

  programs.kdeconnect.enable = true;
}
