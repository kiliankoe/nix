{ pkgs, lib, ... }:
{
  environment.systemPackages =
    with pkgs;
    [
      # language servers
      just-lsp
      marksman # markdown
      nixd
      typescript-language-server
      vscode-langservers-extracted # json/html/css/eslint
      yaml-language-server

      # formatters
      biome # js/ts/json, driven by hx-biome-format in home/programs/helix.nix
      # just's own --fmt overwrites in place and is behind --unstable, so it can't
      # serve as helix's formatter, which pipes stdin to stdout.
      just-formatter
      prettier # markdown

      bun
      # nodejs
      rustup

      chafa
      ddate
      delta
      devenv
      dive
      ffmpeg
      genact
      heh
      hyperfine
      just
      lucky-commit
      lychee
      # mitmproxy
      # mitmproxy2swagger
      openapi-tui
      pi-coding-agent
      ripgrep-all
      somafm-cli
      tealdeer
      tokei
      typst
      watchexec
      yazi
      yt-dlp
    ]
    ++ lib.optionals (!pkgs.stdenv.isDarwin) [
      # claude is installed via homebrew on darwin hosts because that's faster to receive updates
      claude-code
    ];
}
