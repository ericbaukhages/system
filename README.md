# system

This repo is the single source of truth for my system configurations: NixOS hosts, macOS machines, and dotfiles managed with home-manager.

The goal is to be able to stand up a new machine with a one-liner and have everything I care about applied automatically.

## What's in here

| Path | Purpose |
|------|---------|
| `flake.nix` | Top-level Nix flake entry point for all hosts and home configurations |
| `hosts/` | Per-machine NixOS and nix-darwin configurations |
| `home/` | Reusable home-manager modules (shell, editor, git, etc.) |
| `modules/` | Shared NixOS/system modules |
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

Rebuild the current machine:

```bash
sudo nixos-rebuild switch --flake .
```

Build a fresh installer image with this config baked in:

```bash
nix build .#nixosConfigurations.iso.config.system.build.isoImage
```

### macOS

TODO: add the nix-darwin one-liner installer.

## Secrets

TODO: decide on sops-nix, agenix, or another secrets management approach.

## Notes

- This is a work in progress. Expect rough edges while the structure settles.
- Right now the flake targets `nixos-26.05`.
