{ config, pkgs, ... }:

{
  services.xserver.enable = true;

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
    options = "ctrl:nocaps";
  };

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  programs.firefox.enable = true;
  programs._1password.enable = true;
  programs._1password-gui.enable = true;

  programs.dconf.profiles.user.databases = [
    {
      lockAll = true;
      settings = {
        "org/gnome/desktop/input-sources" = {
          xkb-options = [ "ctrl:nocaps" ];
        };
        "org/gnome/desktop/peripherals/touchpad" = {
          natural-scroll = true;
        };
      };
    }
  ];
}
