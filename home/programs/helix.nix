{ config, ... }:
let
  # nixd evaluates real flake outputs, so the exprs below have to point at this repo.
  flake = "${config.home.homeDirectory}/nix";
in
{
  programs.helix = {
    enable = true;

    settings = {
      theme = "onedark";

      editor = {
        line-number = "relative";
        mouse = true;
        scrolloff = 5;
        trim-trailing-whitespace = true;
        shell = [
          "zsh"
          "-c"
        ];

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        file-picker = {
          hidden = false;
        };

        indent-guides = {
          render = true;
          character = "│";
        };

        soft-wrap = {
          enable = true;
        };

        # Mirrors Zed's autosave = "on_window_change".
        auto-save = {
          focus-lost = true;
        };
      };
    };

    languages = {
      # nixd over nil: it evaluates the flake, so it completes nixpkgs attrs and
      # NixOS/nix-darwin/home-manager option paths. nil can't do either.
      # Helix answers workspace/configuration by indexing `config` with the section
      # the server asks for, and nixd asks for "nixd" — hence the doubled nesting.language
      language-server.nixd.config.nixd = {
        nixpkgs.expr = ''import (builtins.getFlake "${flake}").inputs.nixpkgs { }'';
        options = {
          # One host per option system is enough; the schema is shared across hosts.
          nix-darwin.expr = ''(builtins.getFlake "${flake}").darwinConfigurations.cassini.options'';
          nixos.expr = ''(builtins.getFlake "${flake}").nixosConfigurations.kepler.options'';
          home-manager.expr = ''(builtins.getFlake "${flake}").darwinConfigurations.cassini.options.home-manager.users.type.getSubOptions [ ]'';
        };
      };

      language = [
        {
          name = "nix";
          language-servers = [ "nixd" ];
          formatter = {
            command = "nixfmt";
          };
        }
      ];
    };
  };
}
