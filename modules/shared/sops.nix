{
  config,
  pkgs,
  lib,
  ...
}:
{
  # TODO: Read this from op? At least on macOS?
  # Would make it interesting to bootstrap new machines though.
  sops.age.keyFile =
    if pkgs.stdenv.isDarwin then
      "/Users/kilian/.config/sops/age.key"
    else
      "/home/kilian/.config/sops/age.key";
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
}
