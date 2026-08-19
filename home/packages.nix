{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    codex
    fd
    fzf
    htop
    just
    nerd-fonts.iosevka-term
    ripgrep
    tig
    tree
    typescript-language-server
    vscode-langservers-extracted
    yt-dlp
  ];
}
