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
      alias nhb="nh os build -H ${config.networking.hostName} ."
      alias nhs="nh os switch -H ${config.networking.hostName} ."
      alias ls='ls --color=auto'
      alias l='ls -lAh --color=auto'
    '';
  };
}
