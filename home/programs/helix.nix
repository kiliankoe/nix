_: {
  programs.helix = {
    enable = true;

    settings = {
      theme = "onedark";

      editor = {
        line-number = "relative";
        mouse = true;
        scrolloff = 5;
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
      };

      # Custom keybindings
      keys.normal = {
        space.f = "file_picker";
        space.F = "file_picker_in_current_directory";
      };
    };

    languages = {
      language = [
        {
          name = "nix";
          auto-format = true;
          formatter = {
            command = "nixfmt";
          };
        }
        {
          name = "rust";
          auto-format = true;
        }
        {
          name = "go";
          auto-format = true;
        }
        {
          name = "typescript";
          auto-format = true;
        }
        {
          name = "javascript";
          auto-format = true;
        }
      ];
    };
  };
}
