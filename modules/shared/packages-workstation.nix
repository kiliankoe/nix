{ pkgs, lib, ... }:
{
  environment.systemPackages =
    with pkgs;
    [
      nil
      nixd

      bun
      nodejs
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
      opencode
      ripgrep-all
      tealdeer
      tokei
      yazi
      yt-dlp
      zola
    ]
    ++ lib.optionals (!pkgs.stdenv.isDarwin) [
      # claude is installed via homebrew on darwin hosts because that's faster to receive updates
      claude-code
    ];
}
