{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # Steel plugins for steelix, vendored from flake inputs so forge (steel's pm) never
  # has to run. Steel resolves `(require "<cog>/<file>.scm")` under $STEEL_HOME/cogs,
  # so each attr name has to match that cog's `package-name`. $STEEL_HOME itself
  # (~/.steel) stays a real writable dir, since steel caches compiled modules there.
  steelCogs = {
    forest = inputs.forest-hx;
    oil = inputs.oil-hx;
    showkeys = inputs.showkeys-hx;
    # dependencies, not required directly: notify by forest and oil, glyph by forest
    notify = inputs.notify-hx;
    glyph = inputs.glyph-hx;
  };

  # steelix calls its binary `hx` too, so rename it instead of letting the two shadow
  # each other. Both read ~/.config/helix, which is why everything below is shared.
  # only init.scm is steelix-only.
  shx = pkgs.runCommand "steelix-shx" { } ''
    mkdir -p $out/bin
    ln -s ${lib.getExe pkgs.steelix} $out/bin/shx
  '';

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
in
{
  home.packages = [ shx ];

  home.file = lib.mapAttrs' (
    name: src: lib.nameValuePair ".steel/cogs/${name}" { source = src; }
  ) steelCogs;

  # Only steelix reads these. Keybinds for plugin commands have to live here rather
  # than in `settings.keys` below, otherwise they would be rejected by helix, which
  # validates typed commands while parsing config.toml.
  xdg.configFile = {
    # Loaded before init.scm. steelix auto-creates it when absent; declaring it empty
    # keeps the config dir fully managed.
    "helix/helix.scm".text = "";

    "helix/init.scm".text = ''
      ;; `keymap` is a macro, so it has to be required before use or steel
            ;; evaluates `(global)` as a call. forest.hx's README omits this line.
            (require "helix/keymaps.scm")
            (require "forest/forest.scm")
            (require "oil/oil.scm")
            (require "showkeys/showkeys.scm")

            (forest-configure! 'left #:ignore (list ".git" "result" "target"))
            (forest-set-style! 'snacks)

            ;; oil.hx's README puts its bindings in config.toml, but that file is shared
            ;; with plain hx, which rejects unknown typed commands while parsing it.
            (keymap (global)
                    (normal (space (e ":forest-open")
                                   (K ":showkeys-toggle")
                                   (o (o ":oil")
                                      (e ":oil-enter")
                                      (b ":oil-back")
                                      (g ":oil-root")
                                      (s ":oil-save")
                                      (r ":oil-refresh")
                                      (q ":oil-close")
                                      (h ":oil-toggle-hidden")
                                      (i ":oil-toggle-git-ignored")
                                      (m (y ":oil-yank")
                                         (x ":oil-cut")
                                         (p ":oil-paste")
                                         (c ":oil-clipboard-clear"))))))
    '';
  };

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
        scrolloff = 12;
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

        lsp = {
          display-inlay-hints = true;
        };

        soft-wrap = {
          enable = true;
        };

        auto-save = {
          focus-lost = true;
        };

        bufferline = "always";
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
        {
          # Helix auto-configures the lsp, only the formatter is missing here.
          name = "just";
          formatter = {
            command = "just-formatter";
          };
        }
        {
          name = "markdown";
          # Keeping auto-format disabled for now since auto-save.focus-lost is enabled
          # auto-format = true;
          formatter = {
            command = "prettier";
            args = [
              "--parser"
              "markdown"
            ];
          };
        }
      ];
    };
  };
}
