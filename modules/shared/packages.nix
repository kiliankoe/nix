{ pkgs, ... }:
{

  environment.systemPackages = with pkgs; [
    # nix
    nh
    nixfmt
    statix
    deadnix

    # tools
    age
    atuin
    bat
    btop
    dua
    eza
    fd
    fzf
    git
    helix
    jq
    lazygit
    ripgrep
    rustypaste-cli
    sops
    sqlite
    tig
    tmux
    tree
    uv
    vim
    witr
    yq
  ];
}
