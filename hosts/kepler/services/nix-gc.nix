_: {
  # angrr removes stale profile generations before nix-gc runs, so the
  # standard GC can actually reclaim the space.
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

  # Automatic garbage collection
  # Removes old generations and unused packages to free up disk space
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Automatic store optimization (deduplication)
  # Replaces identical files in the Nix store with hardlinks
  nix.optimise = {
    automatic = true;
    dates = [ "03:15" ]; # Run daily at 3:15 AM
  };
}
