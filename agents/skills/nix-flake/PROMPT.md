# Nix flake system configuration

This repository manages NixOS hosts, a nix-darwin MacBook, and home-manager user
dotfiles with a Nix flake.

## Layout

- `flake.nix` — top-level flake; defines `nixosConfigurations.t490s`,
  `nixosConfigurations.x250`, `darwinConfigurations.eric-macbook`,
  `homeConfigurations.eric` (x86_64-linux), and `homeConfigurations.eric-darwin`
  (aarch64-darwin).
- `vars.nix` — shared identity values (`fullName`, `userName`, `userEmail`,
  `timeZone`, `defaultLocale`, `domain`, `sshPublicKey`).
- `modules/nixos/` — NixOS modules shared by multiple hosts.
- `modules/darwin/` — nix-darwin modules shared by multiple hosts.
- `workstation/` — primary NixOS workstation (Lenovo T490s).
- `homelab/` — headless NixOS homelab server (Lenovo X250).
- `darwin/` — nix-darwin work MacBook.
- `home/` — reusable home-manager modules, all imported by `home/default.nix`.
- `agents/` — harness-agnostic agent skill and agent prompts.
- `scripts/` — bootstrap and utility scripts.
- `justfile` — common recipes.

## Common commands (run from the repo root)

- `just home` — apply home-manager for Linux (x86_64-linux).
- `just home-darwin` — apply home-manager for macOS (aarch64-darwin).
- `just rebuild` — `sudo nixos-rebuild switch --flake .#t490s`.
- `just rebuild-homelab` — `sudo nixos-rebuild switch --flake .#x250`.
- `just darwin` — `darwin-rebuild switch --flake .#eric-macbook`.
- `just check` — `nix flake check --all-systems`.
- `just fmt` — `nix fmt` (uses `nixfmt-tree`).

## Conventions

- The flake pins `nixos-26.05` and matching `home-manager/release-26.05`.
- `home/default.nix` is shared between Linux and macOS; branch with `pkgs.stdenv.isDarwin`.
- Linux home is at `/home/eric`; macOS home is at `/Users/eric`.
- `home.stateVersion = "26.05"`.
- `home.sessionVariables.SSH_AUTH_SOCK` points to `~/.1password/agent.sock`.
- Node.js is managed per-project with `fnm`; projects can pin versions via `.nvmrc` or `.node-version`.
- New files must be `git add`ed before the flake can see them.
- The repo's `AGENTS.md` is the canonical project context for agents.
