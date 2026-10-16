# NixOS homelab

Opinionated NixOS configuration for a headless Lenovo ThinkPad X250 homelab server.

## Apply

```bash
sudo nixos-rebuild switch --flake .#x250
```

For a fresh install from the NixOS live environment:

```bash
nixos-install --flake .#x250
```

## What it includes

- `systemd-networkd` + `systemd-resolved`
- Tailscale for remote access
- Caddy as a reverse proxy (placeholder page on port 80)
- Podman with Docker compatibility
- The shared home-manager dotfiles

## Hardware

- `hosts/x250/hardware-configuration.nix` is generated from this machine.
- Do not copy it to different hardware without regenerating.

## Local recipe

```bash
just rebuild-homelab
```

## History

This config was originally created by migrating the X250 from Ubuntu Server to
NixOS. The migration plan has been condensed into this README; see the git
history for the full original document.

## Future work

- Add `sops-nix` for secrets.
- Configure Caddy for external domains with automatic TLS.
- Add Podman quadlets or systemd services for self-hosted apps.
