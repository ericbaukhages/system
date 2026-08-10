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

  nixpkgs.config.allowUnfree = true;

  # Keep zsh enabled since the shared home-manager shell config assumes it.
  programs.zsh.enable = true;

  system.stateVersion = 5;
}
