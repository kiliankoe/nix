{
  description = "Unified Nix Configuration for Multiple Machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    ssh-keys = {
      url = "https://github.com/kiliankoe.keys";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      sops-nix,
      ssh-keys,
    }:
    let
      # Helper function to create darwin configurations
      mkDarwin = hostname:
        nix-darwin.lib.darwinSystem {
          modules = [
            ./hosts/${hostname}
            sops-nix.darwinModules.sops
            home-manager.darwinModules.home-manager
            {
              system.configurationRevision = self.rev or self.dirtyRev or null;
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
            }
          ];
        };

      # Helper function to create nixos configurations
      mkNixos = hostname:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/${hostname}
            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
            }
          ];
        };
    in
    {
      darwinConfigurations = {
        # Build with: darwin-rebuild build --flake .#voyager
        voyager = mkDarwin "voyager";

        # Build with: darwin-rebuild build --flake .#cassini
        cassini = mkDarwin "cassini";
      };

      nixosConfigurations = {
        # Build with: nixos-rebuild build --flake .#kepler
        kepler = mkNixos "kepler";

        # Build with: nixos-rebuild build --flake .#cubesat
        cubesat = mkNixos "cubesat";

        # Build with: nixos-rebuild build --flake .#gaia
        gaia = mkNixos "gaia";
      };

    };
}
