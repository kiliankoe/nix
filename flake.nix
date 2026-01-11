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
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";
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
      pre-commit-hooks,
      ssh-keys,
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

      checks =
        let
          deployChecks = builtins.mapAttrs (
            system: deployLib: deployLib.deployChecks self.deploy
          ) deploy-rs.lib;
          preCommitChecks = builtins.listToAttrs (
            map
              (system: {
                name = system;
                value = {
                  pre-commit = pre-commit-hooks.lib.${system}.run {
                    src = ./.;
                    hooks = {
                      nixfmt.enable = true;
                      statix.enable = true;
                      deadnix.enable = true;
                    };
                  };
                };
              })
              [
                "x86_64-linux"
                "aarch64-linux"
                "aarch64-darwin"
                "x86_64-darwin"
              ]
          );
        in
        builtins.mapAttrs (system: checks: checks // (preCommitChecks.${system} or { })) deployChecks;

      devShells = builtins.listToAttrs (
        map
          (system: {
            name = system;
            value = {
              default =
                let
                  pkgs = nixpkgs.legacyPackages.${system};
                in
                pkgs.mkShell {
                  inherit (self.checks.${system}.pre-commit) shellHook;
                  buildInputs = self.checks.${system}.pre-commit.enabledPackages;
                };
            };
          })
          [
            "x86_64-linux"
            "aarch64-linux"
            "aarch64-darwin"
            "x86_64-darwin"
          ]
      );

    };
}
