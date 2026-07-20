{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    fd
    fzf
    htop
    ripgrep
    tig
    tree
  ];
}
