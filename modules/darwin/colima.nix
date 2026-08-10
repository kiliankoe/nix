{ config, pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.colima
    # Docker Desktop/OrbStack bundled this, colima doesn't.
    pkgs.docker-credential-helpers
  ];

  launchd.user.agents.colima = {
    # --foreground is required, without it `colima start` daemonises and returns and
    # launchd tears the whole job down the moment it does.
    command = "${pkgs.colima}/bin/colima start --foreground";

    # colima's own wrapper prepends limactl/docker/qemu/krunkit, but lima reaches the
    # VM over ssh, which lives in the system paths a launchd agent lacks.
    path = [
      "/usr/bin"
      "/bin"
      "/usr/sbin"
      "/sbin"
    ];

    serviceConfig = {
      RunAtLoad = true;
      # Restart on crash, but leave a deliberate `colima stop` stopped.
      KeepAlive.SuccessfulExit = false;
      StandardOutPath = "/Users/${config.system.primaryUser}/Library/Logs/colima.log";
      StandardErrorPath = "/Users/${config.system.primaryUser}/Library/Logs/colima.log";
    };
  };
}
