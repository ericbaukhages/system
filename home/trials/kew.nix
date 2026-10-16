{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.myHome.trials.enable {
    home.packages = [ pkgs.kew ];
  };
}
