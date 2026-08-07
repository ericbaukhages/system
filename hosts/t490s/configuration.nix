{ vars, ... }:

{
  imports = [
    ./hardware-configuration.nix

    ./../../modules/nixos/base.nix
    ./../../modules/nixos/workstation.nix
    ./../../modules/nixos/desktop.nix
    ./../../modules/nixos/packages.nix
    ./../../modules/nixos/tailscale.nix
  ];

  networking.hostName = "t490s";
}
