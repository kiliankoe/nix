{
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
        alias = {
          amend = "commit --amend --no-edit";
          br = "branch";
          ca = "commit -a";
          cam = "commit -am";
          co = "checkout";
          d = "diff";
          dc = "diff --cached";
          find-merge = "!sh -c 'commit=$0 && branch=\${1:-HEAD} && (git rev-list $commit..$branch --ancestry-path | cat -n; git rev-list $commit..$branch --first-parent | cat -n) | sort -k2 -s | uniq -f1 -d | sort -n | tail -1 | cut -f2'";
          fuck = "reset HEAD --hard";
          last = "log -1 HEAD";
          lazystandup = "!git standup | say";
          lg = "log --oneline --all --abbrev-commit --graph --decorate --color";
          ls = "log --pretty=format:'%C(yellow)%h %C(blue)%ad %C(reset)%s%C(green) [%cn]' --decorate --date=short";
          lucky = "!sh -c 'git checkout $(git which $1 -m1)' -";
          prune = "!git fetch -p && git for-each-ref --format '%(refname:short) %(upstream:track)' | awk '$2 == \"[gone]\" {print $1}' | xargs -r git branch -D";
          recent = "for-each-ref --sort=-committerdate --format='%(committerdate:short) %(refname:short)' refs/heads/";
          show-files = "show --name-only";
          st = "status";
          standup = "!git log --all --author=$USER --since='9am yesterday' --format=%s";
          undo = "reset --soft HEAD^";
          unstage = "reset HEAD --";
          vis = "!fork";
          wip = "commit -am 'WIP' --no-verify";
          yolo = "push --force";
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

    ignores = [
      "*.local"
      "*.swo"
      "*.swp"
      "*~"
      ".DS_Store"
      ".swiftpm"
      ".texpadtmp"
      ".vscode/"
      "default.profraw"
      "node_modules/"
    ];
  };
}
