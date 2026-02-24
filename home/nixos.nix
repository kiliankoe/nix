{
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
      alias ls='ls --color=auto'
      alias l='ls -lAh --color=auto'
    '';
  };
}
