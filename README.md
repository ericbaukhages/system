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

### NixOS

On a fresh install, `just` is not yet available. Use the underlying NixOS command first:

```bash
sudo nixos-rebuild switch --flake .
```

After that, `just` is installed and you can use:

```bash
just rebuild
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

## TODO

- [ ] Decide on and implement a secrets management approach (sops-nix or agenix)
- [ ] Add a nix-darwin configuration and `mkDarwinConfig` helper in `flake.nix`
- [ ] Add an ISO installer configuration
- [ ] Add a `scripts/` directory with bootstrap/installer scripts (e.g. `scripts/install-home` for a one-shot Nix + home-manager setup)
- [ ] Add CI checks (e.g. `nix flake check`) on push

## Notes

- This is a work in progress. Expect rough edges while the structure settles.
- Right now the flake targets `nixos-26.05`.
- Parts of this repository were written or refined with the help of AI coding assistants (e.g. OpenCode, Codex).

## Inspiration

- [chenglab](https://github.com/eh8/chenglab) — a tidy Nix/NixOS multi-machine setup whose `machines/`/`modules/`/`services/` layout and use of `vars.nix` heavily influenced this repo's structure.
