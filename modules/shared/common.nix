{ ... }:
{
  imports = [ ./k.nix ];

  nixpkgs.config.allowUnfree = true;

  programs.nix-index-database.comma.enable = true;
}
