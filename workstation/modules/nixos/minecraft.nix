{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    mcpelauncher-client
    mcpelauncher-ui-qt
  ];
}
