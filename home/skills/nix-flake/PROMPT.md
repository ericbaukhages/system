# Nix flake system configuration

This repository manages NixOS hosts and home-manager user dotfiles with a Nix flake.

## Layout

- `flake.nix` — top-level flake; defines `nixosConfigurations.t490s`, `nixosConfigurations.x250`, `darwinConfigurations.eric-macbook`, `homeConfigurations.eric` (x86_64-linux), and `homeConfigurations.eric-darwin` (aarch64-darwin).
- `vars.nix` — shared identity values (`fullName`, `userName`, `userEmail`, `timeZone`, `defaultLocale`, `domain`, `sshPublicKey`).
- `hosts/` — per-machine configurations. Currently `hosts/t490s/`, `hosts/x250/`, and `hosts/eric-macbook/`.
- `modules/nixos/` — shared NixOS/system modules.
- `home/` — reusable home-manager modules, all imported by `home/default.nix`.
- `justfile` — common recipes.

## Common commands (run from the repo root)

- `just home` — apply home-manager for Linux (x86_64-linux).
- `just home-darwin` — apply home-manager for macOS (aarch64-darwin).
- `just rebuild` — `sudo nixos-rebuild switch --flake .#t490s`.
- `just check` — `nix flake check --all-systems`.
- `just fmt` — `nix fmt` (uses `nixfmt-tree`).

## Conventions

- The flake pins `nixos-26.05` and matching `home-manager/release-26.05`.
- `home/default.nix` is shared between Linux and macOS; branch with `pkgs.stdenv.isDarwin`.
- Linux home is at `/home/eric`; macOS home is at `/Users/eric`.
- `home.stateVersion = "26.05"`.
- `home.sessionVariables.SSH_AUTH_SOCK` points to `~/.1password/agent.sock`.
- New files must be `git add`ed before the flake can see them.
- The repo's `AGENTS.md` is the canonical project context for agents.
