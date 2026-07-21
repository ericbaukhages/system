{ config, pkgs, vars, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  home.username = vars.userName;
  home.homeDirectory = if isDarwin then "/Users/${vars.userName}" else "/home/${vars.userName}";
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
