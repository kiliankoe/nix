{
  description = "Unified Nix Configuration for Multiple Machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin }:
    {
      darwinConfigurations = {
        # Build with: darwin-rebuild build --flake .#voyager
        voyager = nix-darwin.lib.darwinSystem {
          modules = [
            ./hosts/voyager
            {
              system.configurationRevision = self.rev or self.dirtyRev or null;
            }
          ];
        };

        # Build with: darwin-rebuild build --flake .#sojourner
        sojourner = nix-darwin.lib.darwinSystem {
          modules = [
            ./hosts/sojourner
            {
              system.configurationRevision = self.rev or self.dirtyRev or null;
            }
          ];
        };
      };

      nixosConfigurations = {
        # Build with: nixos-rebuild build --flake .#kepler
        kepler = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/kepler
          ];
        };

        # Build with: nixos-rebuild build --flake .#cubesat
        cubesat = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/cubesat
          ];
        };

        # Build with: nixos-rebuild build --flake .#midgard
        midgard = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/midgard
          ];
        };

        # Build ISO with: nix build .#nixosConfigurations.kepler-iso.config.system.build.isoImage
        kepler-iso = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./iso/kepler-iso.nix
          ];
        };
      };

      # Expose package sets for convenience
      darwinPackages = {
        voyager = self.darwinConfigurations.voyager.pkgs;
        sojourner = self.darwinConfigurations.sojourner.pkgs;
      };

      nixosPackages = {
        kepler = self.nixosConfigurations.kepler.pkgs;
        midgard = self.nixosConfigurations.midgard.pkgs;
      };
    };
}
