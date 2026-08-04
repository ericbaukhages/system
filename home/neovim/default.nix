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

    plugins = with pkgs.vimPlugins; [
      vim-abolish
      vim-commentary
      vim-eunuch
      vim-flagship
      vim-fugitive
      vim-repeat
      vim-rhubarb
      vim-sleuth
      vim-surround
      vim-unimpaired
      vim-vinegar
    ];

    initLua = builtins.readFile (
      pkgs.replaceVars ./init.lua {
        inherit (vars) repoPath;
      }
    );
  };
}
