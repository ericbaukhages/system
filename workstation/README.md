# NixOS workstation

Opinionated NixOS configuration for a Lenovo ThinkPad T490s.

## Apply

```bash
sudo nixos-rebuild switch --flake .#t490s
```

## What it includes

- GNOME desktop with custom keybindings
- PipeWire audio
- Firefox, 1Password GUI
- Tailscale
- Quake-terminal extension for a global hotkey terminal
- The shared home-manager dotfiles

## Hardware

- `hosts/t490s/hardware-configuration.nix` is generated from this machine.
- Do not copy it to different hardware without regenerating.

## Local recipe

```bash
just rebuild
```
