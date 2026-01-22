{
  lib,
  modulesPath,
  ...
}:
{
  # Placeholder hardware configuration for cubesat (Hetzner VPS).
  # Replace with real output from `nixos-generate-config --show-hardware-config` on the VPS.
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot = {
    initrd.availableKernelModules = [
      "ata_piix"
      "uhci_hcd"
      "virtio_pci"
      "virtio_scsi"
      "sd_mod"
      "sr_mod"
    ];
    loader.systemd-boot.enable = lib.mkForce false;
    loader.grub = {
      enable = true;
      device = "/dev/sda";
    };
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  swapDevices = [ ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
