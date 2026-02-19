{
  self,
  nixpkgs,
  nix-darwin,
  home-manager,
  sops-nix,
  inputs,
}:

name:
{
  system,
  darwin ? false,
}:
let
  systemFunc = if darwin then nix-darwin.lib.darwinSystem else nixpkgs.lib.nixosSystem;
  hmModule =
    if darwin then home-manager.darwinModules.home-manager else home-manager.nixosModules.home-manager;
  sopsModule = if darwin then sops-nix.darwinModules.sops else sops-nix.nixosModules.sops;
in
systemFunc {
  inherit system;
  specialArgs = {
    inherit inputs;
  };
  modules = [
    ../hosts/${name}
    sopsModule
    hmModule
    (
      if darwin then
        {
          system.configurationRevision = self.rev or self.dirtyRev or null;
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        }
      else
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        }
    )
  ]
  ++ nixpkgs.lib.optionals (!darwin) [ inputs.angrr.nixosModules.angrr ];
}
