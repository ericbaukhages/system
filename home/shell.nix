{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      path = "${config.home.homeDirectory}/.zsh_history";
      size = 10000;
      save = 10000000000;
    };

    shellAliases = {
      a = "tmux attach";
    };

    initContent = ''
      setopt extendedglob nomatch notify
      unsetopt autocd beep
      bindkey -e
      zstyle :compinstall filename '${config.home.homeDirectory}/.zshrc'
    '';
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.tmux = {
    enable = true;
    mouse = true;
    prefix = "C-a";
    extraConfig = ''
      set -g default-terminal "screen-256color"
    '';
  };
}
