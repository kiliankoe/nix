{ ... }:
{
  imports = [ ./k.nix ];

  nixpkgs.config.allowUnfree = true;
}
