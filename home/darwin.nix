{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.sessionVariables = {
    # macOS uses 'open' for default browser
    BROWSER = "open";
  };

  home.homeDirectory = lib.mkForce "/Users/kilian";

  programs.zsh = {
    initContent = ''
      alias brewup="brew upgrade && brew cleanup"
      alias nu="cd ~/nix && nix flake update && cd -"
      alias nhb="nh darwin build -H $(hostname -s) ~/nix"
      alias nhs="nh darwin switch -H $(hostname -s) ~/nix"
      # BSD ls flags
      alias ls='ls -G'
      alias l='ls -lAhG'
    '';
  };
}
