{ config, lib, ... }:

{
  options.myHome.trials.enable = lib.mkEnableOption "trial command-line tools";

  imports = [
    ./codex.nix
    ./ghgrab.nix
    ./kew.nix
    ./leaf.nix
    ./tuxedo.nix
  ];

  config.myHome.trials.enable = lib.mkDefault false;
}
