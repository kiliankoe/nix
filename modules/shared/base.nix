{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  
  environment.systemPackages = with pkgs; [
    # Nix stuff
    nh
    nixfmt

    # Core development tools
    atuin
    bat
    btop
    bun
    claude-code
    codex
    fd
    git
    gping
    helix
    hyperfine
    jq
    lazygit
    mitmproxy
    mitmproxy2swagger
    neofetch
    ripgrep-all
    tealdeer
    tokei
    tree
    vim

    # Programming languages and tools
    go
    nodejs_24
    rustup
    uv

    # Utilities
    ddate
    heh
    lucky-commit
    yt-dlp
  ];
}
