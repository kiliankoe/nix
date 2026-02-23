{ pkgs, inputs, ... }:
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
    uv

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
    helix
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
    witr
    yazi
    yt-dlp
    zola

    # macOS-specific
    _1password-cli
    dedup-darwin
    terminal-notifier

    inputs.npr.packages.${pkgs.system}.default
  ];
}
