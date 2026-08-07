{
  config,
  pkgs,
  vars,
  ...
}:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = vars.timeZone;

  i18n.defaultLocale = vars.defaultLocale;
  i18n.extraLocaleSettings = {
    LC_ADDRESS = vars.defaultLocale;
    LC_IDENTIFICATION = vars.defaultLocale;
    LC_MEASUREMENT = vars.defaultLocale;
    LC_MONETARY = vars.defaultLocale;
    LC_NAME = vars.defaultLocale;
    LC_NUMERIC = vars.defaultLocale;
    LC_PAPER = vars.defaultLocale;
    LC_TELEPHONE = vars.defaultLocale;
    LC_TIME = vars.defaultLocale;
  };

  users.users.${vars.userName} = {
    isNormalUser = true;
    description = vars.fullName;
    extraGroups = [
      "wheel"
    ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  nixpkgs.config.allowUnfree = true;

  networking.firewall.enable = true;

  system.stateVersion = "26.05";
}
