{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Global opencode configuration. Project-specific overrides (e.g., extra
  # instructions, repo-local skills) should live in the project's own
  # `opencode.json` or `.opencode/` directory so they are versioned with the
  # repo, not with home-manager.
  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";

    # Global skills directory. Skills are discovered from ./skills/<name>/
    # (PROMPT.md + default.nix) and emitted to ~/.config/opencode/skills/.
    skills = {
      paths = [
        "${config.home.homeDirectory}/.config/opencode/skills"
      ];
    };

    # Optional global instructions file.
    instructions = [
      "${config.home.homeDirectory}/.config/opencode/instructions/global.md"
    ];

    # Enable LSP support (built-in language servers).
    lsp = true;
  };

  # Discover immediate subdirectories under a path.
  discoverDirs =
    path: lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir path));

  mkSkill =
    name:
    let
      dir = ./skills/${name};
      meta = import dir;
    in
    {
      name = "opencode/skills/${meta.name}/SKILL.md";
      value = {
        text = ''
          ---
          name: ${meta.name}
          description: ${meta.description}
          ---

          ${builtins.readFile (dir + "/PROMPT.md")}
        '';
      };
    };

  mkAgent =
    name:
    let
      dir = ./agents/${name};
      meta = import dir;
    in
    {
      name = "opencode/agents/${meta.name}.md";
      value = {
        text = ''
          ---
          description: ${meta.description}
          mode: ${meta.mode}
          ---

          ${builtins.readFile (dir + "/PROMPT.md")}
        '';
      };
    };

  skillFiles = lib.listToAttrs (map mkSkill (discoverDirs ./skills));
  agentFiles = lib.listToAttrs (map mkAgent (discoverDirs ./agents));
in
{
  # Install opencode if it is available in the pinned nixpkgs. If it is not yet
  # packaged, manage the binary separately and the config files below will still
  # be emitted.
  home.packages = lib.optional (pkgs ? opencode) pkgs.opencode;

  xdg.configFile = {
    "opencode/opencode.json".text = builtins.toJSON opencodeConfig;
    "opencode/instructions/global.md".text = ''
      # Global instructions

      - Be concise and accurate.
      - Prefer small, focused edits.
      - Validate Nix changes with `just check` before considering a task done.
      - This is a Nix flake; new files must be staged with `git add` before the flake can see them.
    '';
  }
  // skillFiles
  // agentFiles;
}
