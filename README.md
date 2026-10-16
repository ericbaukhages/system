# system

Opinionated Nix configurations for the systems I run.

This is a monorepo with clear boundaries: each top-level directory is a separate
concern with its own README and entry point. The goal is a one-command restore
on any system.

## Layout

| Path | Purpose |
|---|---|
| `flake.nix` | Single entry point for all NixOS, nix-darwin, and home-manager outputs |
| `vars.nix` | Shared identity values (name, email, timezone, SSH key) |
| `modules/` | Modules shared by multiple systems |
| `workstation/` | Primary NixOS workstation (Lenovo T490s) |
| `homelab/` | Headless NixOS homelab server (Lenovo X250) |
| `darwin/` | nix-darwin configuration for a work MacBook |
| `home/` | home-manager dotfiles shared across Linux and macOS |
| `agents/` | Harness-agnostic agent skill and agent prompts |
| `scripts/` | Bootstrap and utility scripts |
| `docs/` | Research, plans, and reference notes |

## Restore / apply matrix

Run these from the repo root.

| System | Flake output | Command |
|---|---|---|
| NixOS workstation | `#t490s` | `sudo nixos-rebuild switch --flake .#t490s` |
| NixOS homelab | `#x250` | `sudo nixos-rebuild switch --flake .#x250` |
| macOS work laptop | `#eric-macbook` | `darwin-rebuild switch --flake .#eric-macbook` |
| Home dotfiles (Linux) | `#eric` | `nix run home-manager -- switch --flake .#eric` |
| Home dotfiles (macOS) | `#eric-darwin` | `nix run home-manager -- switch --flake .#eric-darwin` |

See the README in each system directory for hardware notes, opinions, and any
manual prerequisites.

## Common recipes

```bash
just rebuild          # apply NixOS workstation config
just rebuild-homelab  # apply NixOS homelab config
just darwin           # apply nix-darwin config
just home             # apply home-manager on Linux
just home-darwin      # apply home-manager on macOS
just check            # nix flake check --all-systems
just fmt              # nix fmt
```

## Node.js

Node is managed per-project with [fnm](https://github.com/Schniz/fnm). Projects
can pin a version with `.nvmrc` or `.node-version`, and `fnm` switches
automatically on `cd`. Set a default with `fnm default <version>`.

## Trial tools

Experimental CLI tools live in `home/trials/` and are gated by
`myHome.trials.enable`. Enable them in your home configuration when you want to
try something, and remove or promote them later.

## Agents

Agent prompts live in `agents/` and are harness-agnostic. `home/opencode.nix` is
the OpenCode adapter that installs those prompts into `~/.config/opencode/`. To
switch harnesses, add a new adapter under `home/` and import it instead.

## Status

This is a work in progress. The T490s workstation is the primary daily driver;
the X250 homelab and MacBook configs are in place but may need hardware-specific
tweaks when first applied.

## Inspiration

- [chenglab](https://github.com/eh8/chenglab) — tidy multi-machine Nix setup
  whose layout influenced an earlier version of this repo.
- [Omarchy](https://omarchy.org/) — opinionated, reference-first approach to
  personal computing configs.
