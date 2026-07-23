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
      less = "less --mouse";
      tree = "tree --dirsfirst -I 'node_modules|dist|vendor'";
    };

    # Completion zstyles must be defined before compinit runs, otherwise the
    # completion system ignores them. Home Manager runs compinit at order 1000,
    # so we place this at order 550 (before completion initialization).
    initContent = lib.mkMerge [
      (lib.mkOrder 550 ''
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
      '')

      (lib.mkOrder 1000 ''
        # Interactive helpers
        j() {
          cd "$(zoxide query --list | fzf)"
        }

        g() {
          git checkout $(git branch -a --format="%(refname:short)" --sort="-authordate" | fzf | sed 's|origin/||g')
        }
      '')
    ];
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
    extraConfig = ''
      set -g default-terminal "screen-256color"
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      add_newline = false;
      format = "$character$directory$git_branch$git_status";

      character = {
        success_symbol = "[➜](bold green) ";
        error_symbol = "[➜](bold red) ";
      };

      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
        style = "bold cyan";
      };

      git_branch = {
        format = "[git:\\(](bold blue)[$branch](bold red)[\\)](bold blue) ";
        symbol = "";
      };

      git_status = {
        format = "([$all_status$ahead_behind](bold yellow) )";
      };

    };
  };
}
