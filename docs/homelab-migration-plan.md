# Homelab migration plan: NixOS on the ThinkPad X250

## Goal

Move the Ubuntu Server install on the ThinkPad X250 to NixOS and manage it from this flake alongside the existing T490s workstation. The X250 will become a headless application server for personal/home apps, with Caddy as a reverse proxy, Podman for containerized workloads, and Tailscale for remote access.

## Naming convention

Hosts are named after the physical device. Roles are expressed as reusable modules under `modules/nixos/`.

| Device | Hostname | Directory | Role |
|---|---|---|---|
| Lenovo T490s | `t490s` | `hosts/t490s/` | workstation |
| Lenovo X250 | `x250` | `hosts/x250/` | homelab / server |

This keeps hostnames unique and stable while allowing the same role module to be reused if another workstation or server is added later.

## Role modules

New and updated modules under `modules/nixos/`:

| Module | Purpose |
|---|---|
| `base.nix` | Common base: Nix flakes, systemd-boot, locale/timezone, user `eric`, `zsh`, firewall, `stateVersion`. Hostname and network management are removed so hosts can set them. |
| `workstation.nix` | Enables `NetworkManager` and adds the user to the `networkmanager` group. Imported by `hosts/t490s`. |
| `server.nix` | Enables `systemd-networkd` and `resolved`. Imported by `hosts/x250`. |
| `caddy.nix` | Enables Caddy with a placeholder page on port 80; opens ports 80 and 443. |
| `podman.nix` | Enables Podman with Docker compatibility. |

Existing modules reused as-is:

- `desktop.nix` — imported only by `hosts/t490s`.
- `packages.nix` — imported by both hosts.
- `tailscale.nix` — imported by both hosts; login is manual for now.

## Files to create and modify

### Modify

- `flake.nix` — replace the single `nixos` configuration with `t490s` and `x250` entries.
- `modules/nixos/base.nix` — remove hostname, NetworkManager, and the `networkmanager` group so hosts and role modules can set them.
- `hosts/nixos/configuration.nix` — move to `hosts/t490s/configuration.nix`, set hostname to `t490s`, import `workstation.nix`.
- `hosts/nixos/hardware-configuration.nix` — move to `hosts/t490s/hardware-configuration.nix`.
- `justfile` — update the `rebuild` recipe to target `.#t490s`; add a `rebuild-homelab` recipe for building `.#x250`.

### Create

- `hosts/t490s/configuration.nix` (rename from `hosts/nixos/configuration.nix`).
- `modules/nixos/workstation.nix`.
- `modules/nixos/server.nix`.
- `modules/nixos/caddy.nix`.
- `modules/nixos/podman.nix`.
- `hosts/x250/configuration.nix`.
- `hosts/x250/hardware-configuration.nix` (generated on the X250 during install and committed afterward).
- This file: `docs/homelab-migration-plan.md`.

## Implementation phases

### Phase 1: Restructure the existing workstation

1. Rename `hosts/nixos/` to `hosts/t490s/`.
2. Update `flake.nix` to declare `nixosConfigurations.t490s` and `nixosConfigurations.x250`.
3. Refactor `modules/nixos/base.nix` to be hostname- and network-agnostic.
4. Create `modules/nixos/workstation.nix` for NetworkManager.
5. Update `hosts/t490s/configuration.nix` to set `networking.hostName = "t490s"` and import `workstation.nix`.
6. Update `justfile` so the local rebuild targets `.#t490s`.
7. Run `just check` to verify.
8. Apply to the T490s:
   ```bash
   sudo nixos-rebuild switch --flake .#t490s
   ```

### Phase 2: Add the `x250` homelab configuration

1. Create `modules/nixos/server.nix` (systemd-networkd + resolved).
2. Create `modules/nixos/caddy.nix` (placeholder page, firewall ports 80/443).
3. Create `modules/nixos/podman.nix` (Podman + Docker compat).
4. Create `hosts/x250/configuration.nix` importing `base.nix`, `packages.nix`, `tailscale.nix`, `server.nix`, `caddy.nix`, and `podman.nix`.
5. Run `just check` to verify both configurations build.

### Phase 3: Install NixOS on the X250

1. Flash the NixOS minimal ISO to a USB drive.
2. Boot the X250 from USB.
3. Partition and format the disk:
   - 512 MB EFI system partition (`/boot`, `vfat`)
   - Remainder as root partition (`/`, `ext4`)
   - 8 GB swapfile on root
4. Mount partitions and enable swap.
5. Clone this flake repository onto the live environment.
6. Generate the hardware configuration:
   ```bash
   nixos-generate-config --root /mnt
   ```
7. Copy `/mnt/etc/nixos/hardware-configuration.nix` into `hosts/x250/hardware-configuration.nix` in the repo.
8. Install NixOS from the flake:
   ```bash
   nixos-install --flake .#x250
   ```
9. Reboot.
10. Log in and bring up Tailscale:
    ```bash
    sudo tailscale up
    ```
11. Verify Caddy responds at `http://<x250-ip>`.

### Phase 4: Document and commit

1. Commit all new and modified files, including the generated `hosts/x250/hardware-configuration.nix`.
2. Update this document with any deviations from the plan.

## Decisions captured

| Topic | Decision | Rationale |
|---|---|---|
| Install method | USB ISO, wipe disk | Simplest for a physical machine; no data needs preserving. |
| Networking | DHCP initially | Router and Tailscale will pin the address afterward. |
| Network backend on server | `systemd-networkd` | Conventional for headless NixOS servers; clean for future static IP or bridge config. |
| Container runtime | Podman | Rootless by default, Docker compatibility available. |
| Reverse proxy | Caddy | Simple TLS and reverse proxy for self-hosted apps. |
| Initial Caddy config | Placeholder page on port 80 | Verifies the stack before adding domain/TLS complexity. |
| Secrets | Deferred | No secrets yet; add `sops-nix` when Caddy DNS challenges or app secrets are needed. |
| Tailscale auth | Manual login | No auth key needed for initial setup. |

## TODOs

- Decide on a deployment recipe for the `x250` in the `justfile`. Options:
  - Local `nixos-rebuild build --flake .#x250` for verification only.
  - SSH target deploy: `nixos-rebuild switch --flake .#x250 --target-host x250`.
  - Remote switch over SSH: `ssh x250 "sudo nixos-rebuild switch --flake .#x250"`.
  The recipe should probably be context-aware or explicitly target the remote host.

## Future work

- Add `sops-nix` for encrypted secrets (Tailscale auth keys, Caddy DNS challenge tokens, app credentials).
- Configure Caddy for external domains with automatic TLS.
- Add systemd services or Podman quadlets for self-hosted apps.
- Consider `disko` for declarative disk partitioning if the server is rebuilt frequently.

## References

- NixOS Installation Guide: https://nixos.org/manual/nixos/stable/#sec-installation
- NixOS Options Search: https://search.nixos.org/options
- `sops-nix` documentation (for future secrets management): https://github.com/Mic92/sops-nix
