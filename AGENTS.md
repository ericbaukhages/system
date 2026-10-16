# Agent Notes

This repository is a Nix flake that manages NixOS hosts, a nix-darwin MacBook,
and user dotfiles with home-manager.

## Layout

| Path | Purpose |
|------|---------|
| `flake.nix` | Top-level flake. Defines `nixosConfigurations`, `darwinConfigurations`, and `homeConfigurations`. |
| `vars.nix` | Shared identity values: `fullName`, `userName`, `userEmail`, `timeZone`, `defaultLocale`, `domain`, `sshPublicKey`. Imported into NixOS, nix-darwin, and home-manager via `specialArgs` / `extraSpecialArgs`. |
| `modules/nixos/` | NixOS modules shared by multiple hosts. |
| `modules/darwin/` | nix-darwin modules shared by multiple hosts. |
| `workstation/` | Primary NixOS workstation configuration (Lenovo T490s). |
| `homelab/` | Headless NixOS homelab server configuration (Lenovo X250). |
| `darwin/` | nix-darwin work MacBook configuration. |
| `home/` | Reusable home-manager modules. Each file is imported by `home/default.nix`. |
| `agents/` | Harness-agnostic agent skill and agent prompts. |
| `scripts/` | Bootstrap and utility scripts. |
| `justfile` | Common recipes: `rebuild`, `rebuild-homelab`, `darwin`, `check`, `home`, `home-darwin`, `fmt`. |

## Home-manager modules

- `home/default.nix` — entry point. Sets `home.stateVersion = "26.05"`, imports the other modules, and wires `programs.home-manager.enable = true`.
- `home/packages.nix` — universal daily packages installed via `home.packages`.
- `home/shell.nix` — zsh, zoxide, fzf, tmux, starship, fnm.
- `home/neovim/default.nix` — neovim with `nixd` and `nixfmt`. Loads `home/neovim/init.lua` via `builtins.readFile` + `pkgs.replaceVars` (use `@var@` placeholders in the Lua for Nix-side values like the repository path). New files must be `git add`ed before the flake can see them.
- `home/kitty.nix` — kitty terminal with IosevkaTerm Nerd Font.
- `home/git.nix` — git config.
- `home/ssh.nix` — ssh config.
- `home/opencode.nix` — OpenCode adapter. Emits global config and instructions under `~/.config/opencode/` and installs prompts from `agents/`.
- `home/trials/` — experimental CLI tools gated by `myHome.trials.enable`.
- `agents/skills/<name>/` — harness-agnostic reusable skill prompts (`PROMPT.md` + `default.nix`).
- `agents/agents/<name>/` — harness-agnostic reusable agent prompts (`PROMPT.md` + `default.nix`).

## Common commands

Run from the repo root (where `flake.nix` lives):

```bash
just home              # apply home-manager for Linux (x86_64-linux)
just home-darwin       # apply home-manager for macOS (aarch64-darwin)
just rebuild           # sudo nixos-rebuild switch --flake .#t490s
just rebuild-homelab   # sudo nixos-rebuild switch --flake .#x250
just darwin            # darwin-rebuild switch --flake .#eric-macbook
just check             # nix flake check --all-systems
just fmt               # nix fmt (uses nixfmt-tree)
```

## Conventions

- The flake pins `nixos-26.05` and the matching `home-manager/release-26.05` branch.
- `home/default.nix` is shared between Linux and macOS; use `pkgs.stdenv.isDarwin` to branch when needed.
- Home config is rooted at `/home/eric` on Linux and `/Users/eric` on macOS.
- `home.sessionVariables.SSH_AUTH_SOCK` points to `~/.1password/agent.sock`.
- Node.js is managed per-project with `fnm`; projects can pin versions via `.nvmrc` or `.node-version`.
- The repo is in active development; see `README.md` for the restore matrix and current status.

## Documentation and attribution

- Keep process, design, and learning notes in `docs/`.
- When research or code draws on external sources — repositories, videos, articles, forum posts, or individual people — document the source with a direct link and, when possible, a named credit.
- Agent-generated work is rarely a straight copy, but it is still built from other people's ideas. If a file or decision is inspired by outside material, say so. This applies to code, config, and documentation.
- If a new `docs/` file is created, review it for missing citations before considering the work complete.

## AI-assisted commits

When an agent executes `git commit` on behalf of a human in this repository, the commit message must disclose that it was assisted by a model. Name the current model in the attribution line, for example:

```
Assisted-by: opencode-go/kimi-k2.7-code
```

If the user explicitly asks to skip attribution for a specific commit, honor that exception for that commit only. Enforcement is currently handled by the `commit` skill in `agents/skills/commit/`; repo-level automation (e.g., a commit-msg hook or CI check) can be added later if desired.

## Adding a new user-level program

1. If it is a universal daily tool, add it to `home/packages.nix`.
2. If it is experimental, create a module under `home/trials/` and import it in `home/trials/default.nix`.
3. If it needs configuration, create a new module in `home/<program>.nix` (or add to an existing one) and import it in `home/default.nix`.
4. Run `just check` and then the appropriate `just home` / `just home-darwin` recipe.

## Adding a new system-level module

1. If the module is shared by multiple NixOS hosts, add it under `modules/nixos/`.
2. If it is specific to one system, add it under `<system>/modules/nixos/` (or `<system>/modules/darwin/`).
3. Import the module in the relevant host configuration under `<system>/hosts/<hostname>/configuration.nix`.
4. Run `just check` and the appropriate `just rebuild` / `just darwin` recipe.

## Notes

- `nixd` is configured for Nix LSP support in Neovim.
- `starship` uses Nerd Font glyphs (via `nerd-fonts.iosevka-term`).
- `tmux` prefix is the default `C-b`, mouse is enabled, and `default-terminal` is set to `screen-256color`.
- `fnm` is installed for per-project Node version management.
