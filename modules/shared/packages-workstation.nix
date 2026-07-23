{ pkgs, lib, ... }:
{
  environment.systemPackages =
    with pkgs;
    [
      # language servers
      marksman # markdown
      nixd
      typescript-language-server
      vscode-langservers-extracted # json/html/css/eslint

      bun
      # nodejs
      rustup

      ddate
      dive
      ffmpeg
      genact
      gping
      heh
      hyperfine
      lucky-commit
      lychee
      # mitmproxy
      # mitmproxy2swagger
      openapi-tui
      pi-coding-agent
      ripgrep-all
      tealdeer
      tokei
      typst
      yazi
      yt-dlp
      zola
    ]
    ++ lib.optionals (!pkgs.stdenv.isDarwin) [
      # claude is installed via homebrew on darwin hosts because that's faster to receive updates
      claude-code
    ];
}
