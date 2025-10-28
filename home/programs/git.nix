{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.git = {
    enable = true;

    lfs.enable = true;

    signing.key = "24D7C6B4";

    settings = lib.mkMerge [
      {
        user = {
          name = "Kilian Koeltzsch";
          email = lib.mkDefault "me@kilian.io";
          username = "kiliankoe";
        };
        init = {
          defaultBranch = "main";
        };
        merge = {
          ff = "only";
        };
        push = {
          default = "simple";
        };
        pull = {
          rebase = true;
        };
        core = {
          editor = "hx";
          autocrlf = false;
        };
        diff = {
          colorMoved = "default";
        };
        color = {
          ui = true;
        };
        # // lib.mkIf pkgs.stdenv.isDarwin {
        #   tool = "opendiff";
        #   conflictstyle = "diff3";
        # };
      }
      (lib.mkIf pkgs.stdenv.isDarwin {
        credential.helper = "osxkeychain";
      })
    ];

    aliases = {
      br = "branch";
      ca = "commit -a";
      cam = "commit -am";
      ci = "commit";
      fuck = "reset HEAD --hard";
      last = "log -1 HEAD";
      lg = "log --oneline --all --abbrev-commit --graph --decorate --color";
      lucky = "!sh -c 'git checkout $(git which $1 -m1)' -";
      st = "status";
      staaash = "stash --all";
      staash = "stash --include-untracked";
      stsh = "stash --keep-index";
      unstage = "reset HEAD --";
      vis = "!fork";
      which = "!git branch | grep -i";
      yolo = "push --force";
      standup = "!git log --all --author=$USER --since='9am yesterday' --format=%s";
      lazystandup = "!git standup | say";
    };

    ignores = [
      ".DS_Store"
      "*.swp"
      "*.swo"
      "*~"
      ".vscode/"
      "node_modules/"
      ".env"
      ".env.local"
      ".texpadtmp"
      ".swiftpm"
      "default.profraw"
    ];
  };
}
