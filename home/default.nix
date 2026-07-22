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
}
