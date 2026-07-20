{ config, pkgs, ... }:

{
  home.username = "eric";
  home.homeDirectory = "/home/eric";
  home.stateVersion = "26.05";

  imports = [
    ./packages.nix
    ./git.nix
    ./shell.nix
  ];

  # Let home-manager install and manage itself.
  programs.home-manager.enable = true;
}
