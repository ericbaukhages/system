# Bootstrap and utility scripts

This directory holds scripts for setting up or restoring systems managed by this flake.

## Planned scripts

- `bootstrap-home.sh` — install Nix and apply the home-manager configuration.
- `bootstrap-nixos.sh <hostname>` — install NixOS from a flake host configuration.
- `bootstrap-darwin.sh` — install nix-darwin and apply the macOS configuration.

These are added incrementally as the restore workflow matures.
