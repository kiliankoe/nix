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
    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
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
      deploy-rs,
      ssh-keys,
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

        # Build with: darwin-rebuild build --flake .#cassini
        cassini = nix-darwin.lib.darwinSystem {
          modules = [
            ./hosts/cassini
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
          specialArgs = { inherit inputs; };
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
          specialArgs = { inherit inputs; };
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
      };

      # Deploy with: nix run github:serokell/deploy-rs -- .#kepler
      deploy.nodes = {
        kepler = {
          hostname = "kepler";
          sshUser = "kilian";
          fastConnection = true;
          autoRollback = true;
          magicRollback = true;

          profiles.system = {
            user = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.kepler;
          };
        };

        cubesat = {
          hostname = "cubesat";
          sshUser = "kilian";
          fastConnection = true;
          autoRollback = true;
          magicRollback = true;

          profiles.system = {
            user = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.cubesat;
          };
        };
      };

      # Deployment validation checks
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

    };
}
