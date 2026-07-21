# system

This repo is the single source of truth for my system configurations: NixOS hosts, macOS machines, and dotfiles managed with home-manager.

The goal is to be able to stand up a new machine with a one-liner and have everything I care about applied automatically.

## What's in here

| Path | Purpose |
|------|---------|
| `flake.nix` | Top-level Nix flake entry point for all hosts and home configurations |
| `vars.nix` | Shared user/domain/timezone/identity values used across hosts and home-manager |
| `hosts/` | Per-machine NixOS and nix-darwin configurations |
| `home/` | Reusable home-manager modules (shell, editor, git, etc.) |
| `modules/` | Shared NixOS/system modules |
| `justfile` | Common commands for rebuilding, checking, and applying configurations |
| `scripts/` | Bootstrap and installer scripts |

## Quick start

### Just the dotfiles

If you already have Nix with flakes enabled:

**Linux:**

```bash
nix run home-manager -- switch --flake github:ericbaukhages/system#eric
```

**macOS (Apple Silicon):**

```bash
nix run home-manager -- switch --flake github:ericbaukhages/system#eric-darwin
```

To apply the local checkout instead of the GitHub version:

```bash
nix run home-manager -- switch --flake .#eric        # Linux
nix run home-manager -- switch --flake .#eric-darwin # macOS
```

Or install Nix and apply the config in one step:

```bash
curl -fsSL https://raw.githubusercontent.com/ericbaukhages/system/main/scripts/install-home | bash
```

This only installs the home-manager configuration and does not touch system-level settings.

### NixOS

On a fresh install, `just` is not yet available. Use the underlying NixOS command first:

```bash
sudo nixos-rebuild switch --flake .
```

After that, `just` is installed and you can use:

```bash
just rebuild
```

Build a fresh installer image with this config baked in:

```bash
nix build .#nixosConfigurations.iso.config.system.build.isoImage
```

### macOS

TODO: add the nix-darwin one-liner installer.

## Making changes

Configs for user-level programs live under `home/`. For example, Neovim settings are in `home/neovim.nix`.

Shared system settings live under `modules/nixos/`. Per-machine settings live under `hosts/<hostname>/`.

To change a setting:

1. Edit the relevant file in `home/`, `modules/nixos/`, or `hosts/`.
2. Apply the local checkout with the appropriate command:

   ```bash
   just home        # Linux home-manager
   just home-darwin # macOS home-manager
   just rebuild     # NixOS
   ```

These commands must be run from the repo root (where `flake.nix` lives).

> [!NOTE]
> `just` is included as a system package for NixOS hosts, so it's available after the first rebuild.
> Until then, you can run recipes with `nix run nixpkgs#just -- <recipe>`.

## Secrets

TODO: decide on sops-nix, agenix, or another secrets management approach.

## Notes

- This is a work in progress. Expect rough edges while the structure settles.
- Right now the flake targets `nixos-26.05`.

## Inspiration

- [chenglab](https://github.com/eh8/chenglab) — a tidy Nix/NixOS multi-machine setup whose `machines/`/`modules/`/`services/` layout and use of `vars.nix` heavily influenced this repo's structure.
