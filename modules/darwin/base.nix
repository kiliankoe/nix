{ pkgs, ... }:
{
  imports = [
    ./defaults.nix
  ];

  # Darwin-specific secret definitions
  sops.secrets = {
    "env/homebrew_github_api_token" = { };
  };

  # Using Determinate Nix on Darwin hosts
  nix.enable = false;

  # Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.reattach = true;

  system.primaryUser = "kilian";

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
