{ vars, ... }:

{
  imports = [
    ./hardware-configuration.nix

    ./../../modules/nixos/base.nix
    ./../../modules/nixos/server.nix
    ./../../modules/nixos/packages.nix
    ./../../modules/nixos/tailscale.nix
    ./../../modules/nixos/caddy.nix
    ./../../modules/nixos/podman.nix
  ];

  networking.hostName = "x250";
}
