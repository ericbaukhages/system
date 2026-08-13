{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    curl
    dig
    just
    lua-language-server
    nixd
    nixfmt
    opencode
    xclip
  ];
}
