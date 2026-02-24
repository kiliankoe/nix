{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # nix LSPs
    nil
    nixd

    # languages, package managers
    bun
    ni
    nodejs_24
    rustup

    # tools
    biome
    codex
    ddate
    dive
    ffmpeg
    genact
    github-copilot-cli
    gping
    heh
    hyperfine
    lucky-commit
    lychee
    mitmproxy
    mitmproxy2swagger
    neofetch
    openapi-tui
    opencode
    ripgrep-all
    tealdeer
    tokei
    yazi
    yt-dlp
    zola
  ];
}
