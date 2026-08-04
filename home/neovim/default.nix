{
  config,
  pkgs,
  vars,
  ...
}:

{
  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    defaultEditor = true;

    initLua = builtins.readFile (
      pkgs.replaceVars ./init.lua {
        inherit (vars) repoPath;
      }
    );
  };
}
