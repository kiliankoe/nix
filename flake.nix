{
  description = "Unified Nix Configuration for Multiple Machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin }:
    {
      # macOS configurations
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

      # NixOS configurations
      nixosConfigurations = {
        # Build with: nixos-rebuild build --flake .#mariner
        mariner = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/mariner
          ];
        };

        # Build with: nixos-rebuild build --flake .#midgard
        midgard = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/midgard
          ];
        };
      };

      # Expose package sets for convenience
      darwinPackages = {
        voyager = self.darwinConfigurations.voyager.pkgs;
        sojourner = self.darwinConfigurations.sojourner.pkgs;
      };
      
      nixosPackages = {
        mariner = self.nixosConfigurations.mariner.pkgs;
        midgard = self.nixosConfigurations.midgard.pkgs;
      };
    };
}