{ pkgs, ... }:
{
  # TODO: Read this from op? At least on macOS?
  # Would make it interesting to bootstrap new machines though.
  sops.age.keyFile =
    if pkgs.stdenv.isDarwin then
      "/Users/kilian/.config/sops/age.key"
    else
      "/home/kilian/.config/sops/age.key";
  sops.defaultSopsFile = ../../secrets/secrets.yaml;

  # Disable SSH key usage since we're using age encryption only
  # This silences warnings about missing SSH keys
  sops.age.sshKeyPaths = [ ];
  sops.gnupg.sshKeyPaths = [ ];
}
