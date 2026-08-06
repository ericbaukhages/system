# Agent Notes

This repository is a Nix flake that manages NixOS hosts and user dotfiles with home-manager.

## Layout

| Path | Purpose |
|------|---------|
| `flake.nix` | Top-level flake. Defines `nixosConfigurations.nixos`, `homeConfigurations.eric` (x86_64-linux), and `homeConfigurations.eric-darwin` (aarch64-darwin). |
| `vars.nix` | Shared identity values: `fullName`, `userName`, `userEmail`, `timeZone`, `defaultLocale`, `domain`, `repoPath`, `sshPublicKey`. Imported into NixOS and home-manager via `specialArgs` / `extraSpecialArgs`. |
| `hosts/` | Per-machine configurations. Currently only `hosts/nixos/configuration.nix`. |
| `modules/nixos/` | Shared NixOS/system modules. |
| `home/` | Reusable home-manager modules. Each file is imported by `home/default.nix`. |
| `justfile` | Common recipes: `rebuild`, `check`, `home`, `home-darwin`, `fmt`. |

## Home-manager modules

- `home/default.nix` — entry point. Sets `home.stateVersion = "26.05"`, imports the other modules, and wires `programs.home-manager.enable = true`.
- `home/packages.nix` — packages installed via `home.packages`.
- `home/shell.nix` — zsh, zoxide, fzf, tmux, starship.
- `home/neovim/default.nix` — neovim with `nixd` and `nixfmt`. Loads `home/neovim/init.lua` via `builtins.readFile` + `pkgs.replaceVars` (use `@var@` placeholders in the Lua for Nix-side values like `repoPath`). New files must be `git add`ed before the flake can see them.
- `home/kitty.nix` — kitty terminal with IosevkaTerm Nerd Font.
- `home/git.nix` — git config.
- `home/ssh.nix` — ssh config.

## Common commands

Run from the repo root (where `flake.nix` lives):

```bash
just home          # apply home-manager for Linux (x86_64-linux)
just home-darwin   # apply home-manager for macOS (aarch64-darwin)
just rebuild       # sudo nixos-rebuild switch --flake .
just check         # nix flake check --all-systems
just fmt           # nixfmt .
```

## Conventions

- The flake pins `nixos-26.05` and the matching `home-manager/release-26.05` branch.
- `home/default.nix` is shared between Linux and macOS; use `pkgs.stdenv.isDarwin` to branch when needed.
- Home config is rooted at `/home/eric` on Linux and `/Users/eric` on macOS.
- `home.sessionVariables.SSH_AUTH_SOCK` points to `~/.1password/agent.sock`.
- The repo is in active development; the README has a TODO list including secrets management, nix-darwin, and CI.

## Documentation and attribution

- Keep process, design, and learning notes in `docs/`.
- When research or code draws on external sources — repositories, videos, articles, forum posts, or individual people — document the source with a direct link and, when possible, a named credit.
- Agent-generated work is rarely a straight copy, but it is still built from other people's ideas. If a file or decision is inspired by outside material, say so. This applies to code, config, and documentation.
- If a new `docs/` file is created, review it for missing citations before considering the work complete.

## Adding a new user-level program

1. Create a new module in `home/<program>.nix` (or add to an existing one).
2. Import it in `home/default.nix`.
3. If it needs a package, add it to `home/packages.nix`.
4. Run `just check` and then the appropriate `just home` / `just home-darwin` recipe.

## Adding a new system-level module

1. Add or extend files under `modules/nixos/`.
2. Import the module in the relevant host configuration under `hosts/<hostname>/configuration.nix`.
3. Run `just check` and `just rebuild`.

## Notes

- `nixd` is configured for Nix LSP support in Neovim.
- `starship` uses Nerd Font glyphs (via `nerd-fonts.iosevka-term`).
- `tmux` prefix is `C-a`, mouse is enabled, and `default-terminal` is set to `screen-256color`.
