{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.sessionVariables = {
    BROWSER = "firefox";
  };

  home.homeDirectory = lib.mkDefault "/home/kilian";

  programs.zsh = {
    initContent = ''
      alias nrs="sudo nixos-rebuild switch --flake ."
      alias nrb="sudo nixos-rebuild build --flake ."
      alias ls='ls --color=auto'
      alias l='ls -lAh --color=auto'
    '';
  };
}
