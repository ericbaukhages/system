{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    fd
    fzf
    htop
    just
    nerd-fonts.iosevka-term
    ripgrep
    tig
    tree
  ];
}
