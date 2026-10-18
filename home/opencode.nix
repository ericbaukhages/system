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

    # Global skills directory. Skills are discovered from ../agents/skills/<name>/
    # (PROMPT.md + default.nix) and emitted to ~/.config/opencode/skills/.
    skills = [
      "${config.home.homeDirectory}/.config/opencode/skills"
    ];

    # Optional global instructions file.
    instructions = [
      "${config.home.homeDirectory}/.config/opencode/instructions/global.md"
    ];

    # Disable built-in update checks; this package is managed by Nix.
    update = "disable";

    # MCP servers.
    mcp = {
      servers = {
        firefox-devtools = {
          type = "local";
          command = [
            "npx"
            "-y"
            "@mozilla/firefox-devtools-mcp@latest"
            "--headless"
            "--viewport"
            "1280x720"
          ];
          environment = {
            START_URL = "about:blank";
          };
        };

        todoist = {
          type = "remote";
          url = "https://ai.todoist.net/mcp";
        };
      };
    };
  };

  # Discover immediate subdirectories under a path.
  discoverDirs =
    path: lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir path));

  mkSkill =
    name:
    let
      dir = ../agents/skills/${name};
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
      dir = ../agents/agents/${name};
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

  skillFiles = lib.listToAttrs (map mkSkill (discoverDirs ../agents/skills));
  agentFiles = lib.listToAttrs (map mkAgent (discoverDirs ../agents/agents));
in
{
  # Install the OpenCode v2 CLI from the upstream flake overlay.
  home.packages = [ pkgs.opencode ];

  xdg.configFile = {
    "opencode/opencode.json".text = builtins.toJSON opencodeConfig;
    "opencode/instructions/global.md".text = ''
      # Global instructions

      - Be concise and accurate.
      - Prefer small, focused edits.
    '';
  }
  // skillFiles
  // agentFiles;
}
