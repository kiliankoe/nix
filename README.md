# nix configs

Rebuild with fitting hostname, e.g.:
```
# for voyager, sojourner
darwin-rebuild build --flake ./nix#voyager
nh darwin switch -H Voyager .

# or for mariner
nixos-rebuild build --flake ./nix#mariner
```
