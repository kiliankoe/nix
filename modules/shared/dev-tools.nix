{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Core development tools
    atuin
    bat
    btop
    fd
    git
    gping
    helix
    hyperfine
    jq
    lazygit
    neofetch
    ripgrep
    tealdeer
    tokei
    tree
    vim

    # Programming languages and tools
    go
    nodejs_24
    uv

    # Terminal utilities
    ddate
    heh
    lucky-commit
    yt-dlp
  ];
}
