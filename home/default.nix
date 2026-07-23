{ config, pkgs, vars, ... }:

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
    ./neovim.nix
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
  };
}
