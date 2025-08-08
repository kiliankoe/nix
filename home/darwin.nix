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
      alias brewup="brew update && brew upgrade && brew cleanup"
      # BSD ls flags
      alias ls='ls -G'
      alias l='ls -lAhG'
    '';
  };
}
