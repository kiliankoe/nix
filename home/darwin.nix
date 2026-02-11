{
  lib,
  ...
}:
{
  imports = [
    ./programs/zed.nix
  ];

  home.sessionVariables = {
    # macOS uses 'open' for default browser
    BROWSER = "open";
    # some stuff just doesn't play nicely when using a GUI editor as $EDITOR
    # EDITOR = "zed";
  };

  home.homeDirectory = lib.mkForce "/Users/kilian";

  programs.zsh = {
    initContent = ''
      alias brewout="brew outdated"
      alias brewup="brew upgrade && brew cleanup"
      alias nu="cd ~/nix && nix flake update && cd -"
      alias nhb="nh darwin build -H $(hostname -s) ~/nix"
      alias nhs="nh darwin switch -H $(hostname -s) ~/nix"
      # BSD ls flags
      alias ls='ls -G'
      alias l='ls -lAhG'

      # 1Password-managed secrets
      if command -v op >/dev/null 2>&1; then
        export HOMEBREW_GITHUB_API_TOKEN="$(op read 'op://Private/Homebrew GitHub API Token/Password' 2>/dev/null)"
      fi

      # Homebrew
      eval "$(/opt/homebrew/bin/brew shellenv)"
    '';
  };
}
