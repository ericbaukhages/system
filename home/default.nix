{
  config,
  pkgs,
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
    ./git.nix
    ./ssh.nix
    ./shell.nix
    ./neovim
    ./kitty.nix
  ];

  home.sessionVariables = {
    SSH_AUTH_SOCK = "${config.home.homeDirectory}/.1password/agent.sock";
  };

  # Let home-manager install and manage itself.
  programs.home-manager.enable = true;

  # Make Home Manager-installed .desktop files visible to GNOME.
  xdg.enable = true;

  # Remap GNOME "Run a Command" away from Alt+F2 so function keys stay free.
  dconf.settings = {
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
  };
}
