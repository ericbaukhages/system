{ config, pkgs, lib, ... }:

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

    # Completion zstyles must be defined before compinit runs, otherwise the
    # completion system ignores them. Home Manager runs compinit at order 1000,
    # so we place this at order 550 (before completion initialization).
    initContent = lib.mkOrder 550 ''
      setopt extendedglob nomatch notify
      unsetopt autocd beep
      bindkey -e

      # Completion behavior (before compinit)
      zstyle :compinstall filename '${config.home.homeDirectory}/.zshrc'

      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':completion:*' group-name '''
      zstyle ':completion:*' verbose yes
      zstyle ':completion:*:descriptions' format '%U%B%d%b%u'
      zstyle ':completion:*:messages' format '%d'
      zstyle ':completion:*:warnings' format 'No matches for: %d'
      zstyle ':completion:*:corrections' format '%U%d%u'
      zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
      zstyle ':completion:*' use-compctl false
      zstyle ':completion:*' rehash true
      zstyle ':completion:*' cache-path ${config.home.homeDirectory}/.zcompcache
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
