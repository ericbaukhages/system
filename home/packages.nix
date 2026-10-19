{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Universal daily command-line tools
    fd
    fnm
    fzf
    gh
    htop
    imagemagick
    jq
    just
    nerd-fonts.iosevka-term
    obsidian
    ripgrep
    secretspec
    tig
    todoist
    todoist-electron
    tree
    xdg-utils
    yt-dlp

    # Desktop applications
    libreoffice
    token-monitor

    # Editor language servers
    typescript-language-server
    vscode-langservers-extracted
  ];
}
