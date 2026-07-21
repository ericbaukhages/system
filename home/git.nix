{ vars, ... }:

{
  programs.git = {
    enable = true;

    settings.user = {
      name = vars.fullName;
      email = vars.userEmail;
    };

    settings.init.defaultBranch = "main";
  };
}
