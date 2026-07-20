{ config, ... }:

{
  programs.git = {
    enable = true;

    # TODO: add userName and userEmail once you decide on defaults.
    # userName = "Eric Baukhages";
    # userEmail = "...";
  };
}
