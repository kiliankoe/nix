{
  description = "Unified Nix Configuration for Multiple Machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      sops-nix,
    }:
    {
      darwinConfigurations = {
        # Build with: darwin-rebuild build --flake .#voyager
        voyager = nix-darwin.lib.darwinSystem {
          modules = [
            ./hosts/voyager
            sops-nix.darwinModules.sops
            home-manager.darwinModules.home-manager
            {
              system.configurationRevision = self.rev or self.dirtyRev or null;
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
            }
          ];
        };

        # Build with: darwin-rebuild build --flake .#sojourner
        sojourner = nix-darwin.lib.darwinSystem {
          modules = [
            ./hosts/sojourner
            sops-nix.darwinModules.sops
            home-manager.darwinModules.home-manager
            {
              system.configurationRevision = self.rev or self.dirtyRev or null;
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
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
            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
            }
          ];
        };

        # Build with: nixos-rebuild build --flake .#cubesat
        cubesat = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/cubesat
            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
            }
          ];
        };

        # Build with: nixos-rebuild build --flake .#midgard
        midgard = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/midgard
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
            }
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
        cubesat = self.nixosConfigurations.cubesat.pkgs;
        # midgard = self.nixosConfigurations.midgard.pkgs;
      };

      # Lightweight checks for CI: evaluate all configs and build Linux toplevels
      checks =
        let
          systems = [ "x86_64-linux" ];
        in
        nixpkgs.lib.genAttrs systems (
          system:
          let
            pkgs = import nixpkgs { inherit system; };
          in
          {
            # Evaluate Darwin configs without building (works on Linux runners)
            darwin-voyager-eval = pkgs.runCommand "darwin-voyager-eval" { } ''
              echo ${self.darwinConfigurations.voyager.config.system.build.toplevel.drvPath} > $out
            '';
            darwin-sojourner-eval = pkgs.runCommand "darwin-sojourner-eval" { } ''
              echo ${self.darwinConfigurations.sojourner.config.system.build.toplevel.drvPath} > $out
            '';

            # Evaluate NixOS configs
            nixos-kepler-eval = pkgs.runCommand "nixos-kepler-eval" { } ''
              echo ${self.nixosConfigurations.kepler.config.system.build.toplevel.drvPath} > $out
            '';
            nixos-cubesat-eval = pkgs.runCommand "nixos-cubesat-eval" { } ''
              echo ${self.nixosConfigurations.cubesat.config.system.build.toplevel.drvPath} > $out
            '';
            nixos-midgard-eval = pkgs.runCommand "nixos-midgard-eval" { } ''
              echo ${self.nixosConfigurations.midgard.config.system.build.toplevel.drvPath} > $out
            '';

            # Optional: actually build Linux systems as part of flake checks
            # Comment these out if builds become too heavy for CI
            nixos-kepler-build = self.nixosConfigurations.kepler.config.system.build.toplevel;
            nixos-cubesat-build = self.nixosConfigurations.cubesat.config.system.build.toplevel;
            nixos-midgard-build = self.nixosConfigurations.midgard.config.system.build.toplevel;
          }
        );
    };
}
