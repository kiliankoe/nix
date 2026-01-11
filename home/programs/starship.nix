{ ... }:
{
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;

      format = builtins.concatStringsSep "" [
        "$directory"
        "$git_branch"
        "$git_status"
        "$nix_shell"
        "$nodejs"
        "$python"
        "$rust"
        "$character"
      ];

      directory = {
        style = "green";
        truncation_length = 1;
        truncate_to_repo = false;
      };

      git_branch = {
        symbol = "";
        format = "[git ](blue)[$branch](red) ";
      };

      git_status = {
        format = "[$all_status$ahead_behind]($style) ";
        style = "red";
        conflicted = "!";
        ahead = "↑";
        behind = "↓";
        diverged = "↕";
        untracked = "?";
        stashed = "";
        modified = "*";
        staged = "+";
        renamed = "";
        deleted = "";
      };

      nix_shell = {
        format = "[nix ](cyan)";
        impure_msg = "";
        pure_msg = "";
      };

      nodejs = {
        format = "[node $version ](green)";
        detect_files = [
          "package.json"
          ".nvmrc"
        ];
      };

      python = {
        format = "[py $version ](yellow)";
      };

      rust = {
        format = "[rs $version ](red)";
      };

      character = {
        success_symbol = "[❯](yellow)";
        error_symbol = "[❯](red)";
      };
    };
  };
}
