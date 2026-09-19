{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    codex
    entr
    fd
    fzf
    gh
    htop
    just
    nerd-fonts.iosevka-term
    nodejs
    obsidian
    xdg-utils
    ripgrep
    tig
    todoist
    todoist-electron
    tree
    typescript-language-server
    vscode-langservers-extracted
    whisper-cpp
    wireplumber
    yt-dlp
  ];
}
