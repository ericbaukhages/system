{
  config,
  pkgs,
  lib,
  vars,
  ...
}:

let
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  home.username = vars.userName;
  home.homeDirectory = if isDarwin then "/Users/${vars.userName}" else "/home/${vars.userName}";
  home.stateVersion = "26.05";

  imports = [
    ./packages.nix
    ./scripts.nix
    ./git.nix
    ./ssh.nix
    ./shell.nix
    ./neovim
    ./kitty.nix
    ./opencode.nix
  ];

  home.sessionVariables = {
    SSH_AUTH_SOCK = "${config.home.homeDirectory}/.1password/agent.sock";
  };

  # Let home-manager install and manage itself.
  programs.home-manager.enable = true;

  # Make Home Manager-installed .desktop files visible to GNOME.
  xdg.enable = true;

  # GNOME/dconf settings only apply on Linux. Use mkIf so the module structure
  # does not depend on pkgs during argument resolution (avoids infinite
  # recursion when home-manager evaluates the module).
  dconf.settings = lib.mkIf (!isDarwin) {
    # Remap GNOME "Run a Command" away from Alt+F2 so function keys stay free.
    "org/gnome/desktop/wm/keybindings" = {
      "panel-run-dialog" = [ "<Super>space" ];
      # Unbind input-source switching so it doesn't clash with Super+Space.
      "switch-input-source" = [ ];
      "switch-input-source-backward" = [ ];
    };

    # Enable and configure the quake-terminal extension for a global hotkey
    # terminal. (kitty's own quick_access_terminal kitten relies on the wlr
    # layer-shell protocol, which GNOME/Mutter does not implement, so a GNOME
    # Shell extension is the cleanest Wayland-native approach here.)
    "org/gnome/shell" = {
      enabled-extensions = [
        "quake-terminal@diegodario88.github.io"
      ];
    };

    "org/gnome/shell/extensions/quake-terminal" = {
      terminal-id = "kitty.desktop";
      terminal-shortcut = [ "<Super><Shift>F" ];
      vertical-size = 40;
      horizontal-size = 100;
      horizontal-alignment = 2; # centered
      auto-hide-window = true;
      skip-taskbar = true;
    };

    # Dictation hotkey. This is a work in progress and is not working correctly
    # yet; the shortcut and script may change before it is considered stable.
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/dictate/"
      ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/dictate" = {
      name = "Dictate";
      binding = "<Super><Shift>D";
      command = "${config.home.homeDirectory}/.nix-profile/bin/dictate";
    };
  };
}
