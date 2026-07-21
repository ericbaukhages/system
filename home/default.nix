{ config, pkgs, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  home.username = "eric";
  home.homeDirectory = if isDarwin then "/Users/eric" else "/home/eric";
  home.stateVersion = "26.05";

  imports = [
    ./packages.nix
    ./git.nix
    ./shell.nix
    ./neovim.nix
  ];

  # Let home-manager install and manage itself.
  programs.home-manager.enable = true;
}
