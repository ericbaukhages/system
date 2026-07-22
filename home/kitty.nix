{ config, pkgs, ... }:

{
  programs.kitty = {
    enable = true;

    settings = {
      font_family = "IosevkaTerm Nerd Font";
      font_size = 13;
    };
  };
}
