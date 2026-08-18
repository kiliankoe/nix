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

  # Helix's bundled languages.toml turns on every typescript-language-server inlay
  # hint at full verbosity, which buries the code it annotates: a parameter name on
  # every argument plus a fully expanded structural type on every binding and every
  # callback parameter. typescript-language-server's own defaults are all off, so
  # this verbosity is helix's choice, not the server's.
  # Return types and callback parameter types are the two that cost lines without
  # saying anything the signature doesn't; "literals" keeps the parameter names that
  # disambiguate a bare `0` or `"B"` and drops the ones on already-named arguments.
  tsInlayHints = {
    includeInlayEnumMemberValueHints = true;
    includeInlayFunctionLikeReturnTypeHints = false;
    includeInlayFunctionParameterTypeHints = false;
    includeInlayParameterNameHints = "literals";
    includeInlayParameterNameHintsWhenArgumentMatchesName = false;
    includeInlayPropertyDeclarationTypeHints = true;
    includeInlayVariableTypeHints = true;
  };

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

  hx-biome-format = pkgs.writeShellApplication {
    name = "hx-biome-format";
    runtimeInputs = [ pkgs.biome ];
    text = builtins.readFile ./scripts/hx-biome-format.sh;
  };

  # One binary formats all of these, so the entries only differ by name and by the
  # stock language server they have to restate. biome needs a filename to pick its
  # parser, and helix expands command-line variables in formatter args; the bare
  # basename is enough, since helix already runs the formatter with the document's
  # directory as cwd. Passing %{buffer_name} whole would break instead: it is
  # relative to helix's cwd, not the formatter's.
  biomeLanguages = lib.mapAttrsToList (name: stockServers: {
    inherit name;
    auto-format = true;
    # `language-servers` replaces helix's bundled list rather than extending it, so
    # each language's stock server has to be named again alongside biome. biome is
    # here for its lint diagnostics, which nothing else surfaces — tsserver doesn't
    # know the rules and the formatter can't report them. It stays quiet in projects
    # without a biome config, so this costs nothing outside repos that opted in.
    language-servers = stockServers ++ [
      {
        name = "biome";
        # Formatting goes through the wrapper, which supplies the house style in
        # projects that have no biome config; the LSP would silently fall back to
        # biome's own tabs there.
        except-features = [ "format" ];
      }
    ];
    formatter = {
      command = lib.getExe hx-biome-format;
      args = [ "%{buffer_name}" ];
    };
  }) tsLanguages;

  # Helix only continues *line* comment tokens on newline, so `/** ... */` doc blocks
  # get no leading `*`. Listing it explicitly as a second token makes Enter/o/O continue
  # one.
  # The key has to be the deprecated singular `comment-token`, helix merges this table
  # onto its bundled one, `comment-tokens` is a serde alias for the same field and with
  # both present it errors on the duplicate and falls back to its *entire* default lang
  # config...
  docCommentLanguages = lib.forEach [ "javascript" "jsx" "typescript" "tsx" ] (name: {
    inherit name;
    comment-token = [
      "//"
      "*"
    ];
  });

  tsLanguages = {
    javascript = [ "typescript-language-server" ];
    json = [ "vscode-json-language-server" ];
    jsonc = [ "vscode-json-language-server" ];
    jsx = [ "typescript-language-server" ];
    typescript = [ "typescript-language-server" ];
    tsx = [ "typescript-language-server" ];
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

    # show directories and files in the explorer in different colors
    themes.kilko = {
      # ghostty follows my system theme, this allows for helix to follow along directly
      inherits = "base16_transparent";
      "ui.text.directory" = {
        fg = "sky_blue";
      };
      "diagnostic.error" = {
        underline = {
          style = "curl";
          color = "red";
        };
      };
    };

    settings = {
      theme = "kilko";

      # how long before completion is shown, default is 250ms
      completionTimeout = 50;
      # how many characters are needed before completion is triggered
      completionTriggerLen = 1;

      keys = {
        insert = {
          "A-ret" = [
            "goto_line_end_newline"
            "insert_newline"
          ];
        };
        normal = {
          # Try to unlearn old habits
          up = "no_op";
          down = "no_op";
          left = "no_op";
          right = "no_op";

          "C-g" = [
            ":write-all"
            ":new"
            ":insert-output lazygit"
            # hint helix into restarting mouse-mode
            ":set mouse false"
            ":set mouse true"
            ":buffer-close!"
            ":redraw"
            ":reload-all"
          ];
        };
      };

      editor = {
        line-number = "relative";
        mouse = true;
        scrolloff = 6;
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
          character = "·";
        };

        lsp = {
          display-inlay-hints = true;
          # A TS structural type runs to hundreds of characters, and with soft-wrap on
          # a single hint becomes three lines. Truncate it instead; the full type is
          # still one `space k` away. Global across servers, so it clips nixd too.
          inlay-hints-length-limit = 40;
        };

        # Diagnostics render in the buffer instead of the top-right corner, where a
        # long message was unreadable. The cursor line gets the full wrapped block
        # below it, every other line gets only its most severe diagnostic appended
        # after the line text. Helix suppresses the end-of-line copy of anything the
        # inline filter already caught, so no message shows up twice.
        # `other-lines` stays at its default of "disable": a block per diagnostic
        # across the whole file pushes the code apart faster than it explains
        # anything.
        end-of-line-diagnostics = "hint";
        inline-diagnostics.cursor-line = "hint";

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
        # Type hints are in the way sometimes, this allows quick and easy toggling.
        I = ":toggle lsp.display-inlay-hints";
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

      # lsp-proxy talks LSP over stdio and brokers a shared biome daemon behind it.
      language-server.biome = {
        command = lib.getExe pkgs.biome;
        args = [ "lsp-proxy" ];
      };

      # bash-language-server shells out to shfmt for formatting, whose default
      # de-indents case branches; -ci keeps the style the scripts here are written
      # in. Indentation itself isn't set here: the server takes it from the
      # formatting request, which helix fills from the language's `indent`.
      # A project .editorconfig carrying any shfmt property replaces this table
      # wholesale rather than merging with it, which is the server's own rule.
      language-server.bash-language-server.config.bashIde.shfmt.caseIndent = true;

      # Helix folds the user languages.toml onto its bundled one with
      # merge_toml_values(default, user, 3), and the depth runs out exactly at
      # `config` (root → language-server → <name> → config), so this table replaces
      # the bundled one rather than merging into it. Hence hostInfo and the
      # javascript half being restated: anything omitted here falls back to the
      # server's own default (every hint off), not to helix's `true`.
      language-server.typescript-language-server.config = {
        hostInfo = "helix";
        typescript.inlayHints = tsInlayHints;
        javascript.inlayHints = tsInlayHints;
      };

      # `auto-format` is per-language and defaults to false, so every entry below
      # has to opt in by hand; `editor.auto-format` is only a global kill switch
      # for the flag, not a way to turn it on everywhere. Helix's bundled config
      # sets it for a few dozen languages, none of which are configured here.
      language = [
        {
          name = "nix";
          auto-format = true;
          language-servers = [ "nixd" ];
          formatter = {
            command = "nixfmt";
          };
        }
        {
          # Helix auto-configures the lsp, and formatting goes through it (the
          # server drives shfmt), so there is no formatter block to add.
          name = "bash";
          auto-format = true;
        }
        {
          # Helix auto-configures the lsp, only the formatter is missing here.
          name = "just";
          auto-format = true;
          formatter = {
            command = "just-formatter";
          };
        }
        {
          name = "markdown";
          # disabled so as not to mess with every table;
          # manually running this for the time being
          auto-format = false;
          formatter = {
            command = "prettier";
            args = [
              "--parser"
              "markdown"
            ];
          };
        }
        {
          name = "yaml";
          auto-format = true;
          language-servers = [ "yaml-language-server" ];
        }
      ]
      ++ biomeLanguages
      ++ docCommentLanguages;
    };
  };
}
