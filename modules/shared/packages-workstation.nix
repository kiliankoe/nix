{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    nil
    nixd

    bun
    rustup

    claude-code
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
