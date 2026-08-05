{
  config,
  lib,
  pkgs,
  ...
}:
let
  # nixd evaluates real flake outputs, so the exprs below have to point at this repo.
  flake = "${config.home.homeDirectory}/nix";

  # Helix has no inline blame yet (https://github.com/helix-editor/helix/pull/13133).
  # Space B opens tig show for the commit that last touched the cursor line: full
  # diff, author, and message.
  hx-tig-show = pkgs.writeShellApplication {
    name = "hx-tig-show";
    # git resolves the blamed commit here; tig runs inside the popup and resolves
    # from the interactive PATH there.
    runtimeInputs = [
      pkgs.git
      pkgs.tmux
    ];
    text = builtins.readFile ./scripts/hx-tig-show.sh;
  };

  # Space L opens tig blame so you can walk the line back through its history
  # (`,` reblames the parent).
  hx-tig-blame = pkgs.writeShellApplication {
    name = "hx-tig-blame";
    # Only tmux is invoked by the script itself; tig runs inside the popup and
    # resolves from the interactive PATH there.
    runtimeInputs = [ pkgs.tmux ];
    text = builtins.readFile ./scripts/hx-tig-blame.sh;
  };

  hx-yazi = pkgs.writeShellApplication {
    name = "hx-yazi";
    # Only tmux is invoked by the script itself; yazi runs inside the popup and
    # resolves from the interactive PATH there.
    runtimeInputs = [ pkgs.tmux ];
    text = builtins.readFile ./scripts/hx-yazi.sh;
  };
in
{
  programs.helix = {
    enable = true;

    # ao is great, but show directories and files in the explorer in different colors
    themes.kilko = {
      inherits = "ao";
      "ui.text.directory" = {
        fg = "sky_blue";
      };
    };

    settings = {
      theme = "kilko";

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
          character = ".";
        };

        soft-wrap = {
          enable = true;
        };

        auto-save = {
          focus-lost = true;
        };
      }
      // lib.optionalAttrs pkgs.stdenv.isDarwin {
        # A mouse selection is auto-yanked to the primary register (`*`), but both
        # providers helix picks on macOS (tmux, pasteboard) leave primary unset, so
        # that yank is silently dropped. Aliasing primary to pbcopy makes selecting
        # with the mouse behave like copy-on-select in the terminal.
        # Darwin only — the Linux hosts have no pbcopy and their autodetected
        # provider (tmux/OSC 52) is the one that gets text back to this machine.
        # Note the naming: `yank` reads the clipboard, `paste` writes to it.
        clipboard-provider.custom = {
          yank.command = "pbpaste";
          paste.command = "pbcopy";
          yank-primary.command = "pbpaste";
          paste-primary.command = "pbcopy";
        };
      };

      keys.normal = {
        "C-j" = [
          "extend_to_line_bounds"
          "delete_selection"
          "paste_after"
        ];
        "C-k" = [
          "extend_to_line_bounds"
          "delete_selection"
          "move_line_up"
          "paste_before"
        ];
      };

      keys.normal.space = {
        B = ":sh ${lib.getExe hx-tig-show} '%{buffer_name}' %{cursor_line}";
        L = ":sh ${lib.getExe hx-tig-blame} '%{buffer_name}' %{cursor_line}";
        M = ":sh ${lib.getExe hx-yazi} '%{buffer_name}'";
      };
    };

    languages = {
      # nixd over nil: it evaluates the flake, so it completes nixpkgs attrs and
      # NixOS/nix-darwin/home-manager option paths. nil can't do either.
      # Helix answers workspace/configuration by indexing `config` with the section
      # the server asks for, and nixd asks for "nixd" — hence the doubled nesting.
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
