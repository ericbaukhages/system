{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    codex
    fd
    fzf
    gh
    htop
    just
    nerd-fonts.iosevka-term
    nodejs
    obsidian
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
