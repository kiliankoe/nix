{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:
{
  home.sessionVariables = {
    BROWSER = "firefox";
  };

  home.homeDirectory = lib.mkDefault "/home/kilian";

  programs.zsh = {
    initContent = ''
      alias nhb="nh os build -H ${osConfig.networking.hostName} ~/nix"
      alias nhs="nh os switch -H ${osConfig.networking.hostName} ~/nix"
      alias kepler-deploy='nix run github:serokell/deploy-rs -- ~/nix#kepler'
      alias ls='ls --color=auto'
      alias l='ls -lAh --color=auto'
    '';
  };
}
