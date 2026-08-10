{ vars, ... }:

{
  imports = [
    ./../../modules/darwin/base.nix
  ];

  networking.hostName = "eric-macbook";

  # TODO: add work-specific darwin modules here, e.g.:
  # - ./../../modules/darwin/hammerspoon.nix
  # - ./../../modules/darwin/ollama.nix
  # - ./../../modules/darwin/onepassword.nix
}
