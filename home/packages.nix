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

    # https://github.com/lomirus/live-server (actively maintained Rust rewrite of tapio/live-server)
    live-server

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
