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
      # nixpkgs ships the zed-editor binary as `zeditor` to avoid colliding
      # with another `zed` package; expose the familiar `zed` name here.
      alias zed='zeditor'
    '';
  };
}
