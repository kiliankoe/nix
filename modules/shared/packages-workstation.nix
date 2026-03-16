{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    nil
    nixd

    bun
    rustup

    claude-code
    ddate
    dive
    ffmpeg
    genact
    gping
    heh
    hyperfine
    lucky-commit
    lychee
    # mitmproxy
    # mitmproxy2swagger
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
