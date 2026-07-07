{ ... }:
{
  imports = [
    ./defaults.nix
  ];

  # Using Determinate Nix on Darwin hosts
  nix.enable = false;

  # Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.reattach = true;

  system.primaryUser = "kilian";

  # nix-darwin runs compinit in /etc/zshrc by default, and home-manager runs it
  # again in ~/.zshrc. Each run sees a different fpath, so they invalidate each
  # other's ~/.zcompdump and the completion cache is fully rebuilt twice on
  # every shell start (~1s+). Let home-manager's compinit (which runs last,
  # with the complete fpath) own completion exclusively.
  programs.zsh.enableCompletion = false;
  programs.zsh.enableBashCompletion = false;

  home-manager.backupFileExtension = "backup";
  home-manager.users.kilian = {
    imports = [
      ../../home/common.nix
      ../../home/darwin.nix
    ];
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
