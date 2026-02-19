# Periodic Docker cleanup to reclaim disk space from unused images,
# stopped containers, and unused networks.
_: {
  virtualisation.docker.autoPrune = {
    enable = true;
    dates = "Sun 03:00";
    flags = [
      "--all"
      "--volumes"
    ];
  };
}
