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
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    angrr.url = "github:linyinfeng/angrr";
    angrr.inputs.nixpkgs.follows = "nixpkgs";
    npr.url = "github:faukah/npr";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      sops-nix,
      deploy-rs,
      ...
    }:
    let
      mkSystem = import ./lib/mksystem.nix {
        inherit
          self
          nixpkgs
          nix-darwin
          home-manager
          sops-nix
          inputs
          ;
      };
    in
    {
      darwinConfigurations = {
        voyager = mkSystem "voyager" {
          system = "aarch64-darwin";
          darwin = true;
        };
        cassini = mkSystem "cassini" {
          system = "aarch64-darwin";
          darwin = true;
        };
      };

      nixosConfigurations = {
        kepler = mkSystem "kepler" { system = "x86_64-linux"; };
        cubesat = mkSystem "cubesat" { system = "x86_64-linux"; };
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

      checks = builtins.mapAttrs (_system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
