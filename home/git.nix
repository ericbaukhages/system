{ config, ... }:

{
  programs.git = {
    enable = true;

    settings.user = {
      name = "Eric Baukhages";
      email = "eric.baukhages@gmail.com";
    };

    settings.init.defaultBranch = "main";
  };
}
