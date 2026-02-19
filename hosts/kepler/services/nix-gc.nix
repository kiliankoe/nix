# Nix garbage collection with angrr for intelligent GC root cleanup.
# angrr removes stale profile generations before nix-gc runs, so the
# standard GC can actually reclaim the space.
_: {
  services.angrr = {
    enable = true;
    settings = {
      profile-policies.system = {
        profile-paths = [ "/nix/var/nix/profiles/system" ];
        keep-latest-n = 5;
        keep-booted-system = true;
        keep-current-system = true;
      };
    };
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
