---
title: "macOS-style Super key on NixOS / GNOME"
type: plan
status: proposed
created: 2026-08-07
updated: 2026-08-07
tags: [nixos, gnome, keyd, input, keyboard, macos]
---

# macOS-style Super key on NixOS / GNOME

Goal: make the physical left Alt key on a PC keyboard act like a Mac Command
key — so `Super+C` copies, `Super+V` pastes, `Super+T` opens a new tab, etc. —
while keeping `Ctrl` unchanged in the terminal (matching macOS itself).

## Context

The repository already swaps left Alt and left Super via XKB:

```nix
services.xserver.xkb.options = "ctrl:nocaps,altwin:swap_lalt_lwin";
```

That means the physical key left of the spacebar (Alt on a PC keyboard)
already emits `Super` at the GNOME/Wayland level. This is the right physical
position for a Mac-style Command key. The remaining work is to make that
`Super` key emit `Ctrl` shortcuts inside applications.

## Strategy

Use **keyd**, a low-level input remapper, with the existing XKB swap.

- Keep the XKB swap (`altwin:swap_lalt_lwin`) so physical Alt is still OS
  `Super`.
- Add a keyd `[alt]` layer that translates physical `Alt+<key>` into
  `Ctrl+<key>`.
- Because keyd sees raw keys *before* XKB, unmapped combos such as
  `Alt+Space` pass through as `Alt+Space` and then XKB swaps them to
  `Super+Space`, which GNOME handles.
- Use keyd's **application-aware mapper** so that in Kitty the same
  `Alt+C` / `Alt+V` becomes `Ctrl+Shift+C` / `Ctrl+Shift+V` (Kitty's native
  copy/paste) instead of `Ctrl+C` (SIGINT).

This approach is display-server agnostic and works on Wayland, X11, and even a
VT. It is the strategy used by the keyd project itself for macOS-style
remapping (see the README's "Example 2").

Sources:

- keyd: <https://github.com/rvaiya/keyd>
- keyd application-aware remapping docs: `docs/keyd-application-mapper.scdoc`
  in the keyd repo.
- NixOS `services.keyd` module:
  <https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/hardware/keyd.nix>

## Files to change

1. `modules/nixos/desktop.nix` (or a new `modules/nixos/keyd.nix`)
   - Enable `services.keyd` with the `[alt]` layer.
   - Create the `keyd` group and add `eric` to it.
   - Work around [NixOS/nixpkgs#290161](https://github.com/NixOS/nixpkgs/issues/290161)
     so the mapper can connect to the daemon socket.
   - Install `pkgs.keyd` system-wide for `keyd-application-mapper`.
   - Build and install the keyd GNOME Shell extension, patched for the
     current GNOME version.
   - Enable the extension via dconf.

2. `home/default.nix` (or a new `home/keyd.nix`)
   - Write `~/.config/keyd/app.conf` with the Kitty override.

3. `home/default.nix` (dconf settings)
   - Bind Activities overview to `Super+Space`.
   - Bind "Run a Command" to `Super+Shift+Space`.
   - Disable the single-`Super` tap for Activities.
   - Clear `switch-input-source` / `switch-input-source-backward` because
     they default to the same chords.

4. No Kitty configuration changes are required.
   - Kitty keeps `Ctrl+Shift+C/V` for copy/paste.
   - The mapper translates `Super+C/V` into those only when Kitty is focused.

## Proposed starter keyd mapping

```ini
[ids]
*

[alt]
c = C-c
v = C-v
x = C-x
z = C-z
a = C-a
f = C-f
t = C-t
shift+t = C-S-t
w = C-w
n = C-n
o = C-o
s = C-s
q = C-q
r = C-r
shift+r = C-S-r
l = C-l
```

This is intentionally a small starter set. More mappings can be added
incrementally as the setup is validated.

## Kitty application-aware override

`~/.config/keyd/app.conf`:

```ini
[kitty]
alt.c = C-S-c
alt.v = C-S-v
```

This requires the keyd GNOME extension and `keyd-application-mapper` to be
running. On GNOME the extension manages the mapper's lifecycle once it is
installed and enabled.

## GNOME keybinding changes

The exact dconf paths and defaults are taken from the upstream GNOME gschema
sources (GNOME 48+ / nixos-26.05):

| Action | Schema | Key | Proposed value |
|---|---|---|---|
| Activities overview | `org.gnome.shell.keybindings` | `toggle-overview` | `["<Super>space"]` |
| Run a Command | `org.gnome.desktop.wm/keybindings` | `panel-run-dialog` | `["<Super><Shift>space"]` |
| Disable single-Super tap | `org.gnome.mutter` | `overlay-key` | `""` |
| Input source switcher | `org.gnome.desktop.wm/keybindings` | `switch-input-source` | `[]` |
| Input source switcher back | `org.gnome.desktop.wm/keybindings` | `switch-input-source-backward` | `[]` |

## Known conflicts with GNOME defaults

Mapping a letter in the `[alt]` layer means GNOME never sees the
`Super+<letter>` combo. Some defaults will be overridden:

| Combo | GNOME default | App use we want |
|---|---|---|
| `Super+V` | Toggle message tray | Paste |
| `Super+N` | Focus active notification | New window |
| `Super+S` | Toggle quick settings | Save |
| `Super+A` | App grid | Select all |
| `Super+L` | Lock screen | Focus location bar |
| `Super+1..9` | Switch to application N | Browser tab switching |
| `Super+P` | Switch monitor | Print |

Each conflict can be resolved by either keeping the GNOME default (do not
map that letter in keyd) or accepting the app shortcut and rebinding the
GNOME action elsewhere. The starter set above already overrides several of
these, which is the intended macOS-like behavior.

## Safety and rollback

A bad keyd config can lock the keyboard. The emergency kill chord is:

```text
Backspace + Escape + Enter
```

Held together, this terminates keyd. Start with a minimal mapping (e.g. only
`c` and `v`), rebuild, verify, then expand.

## Implementation status

- [ ] Create `modules/nixos/keyd.nix` or extend `modules/nixos/desktop.nix`
- [ ] Create `home/keyd.nix` for `~/.config/keyd/app.conf`
- [ ] Update GNOME dconf keybindings in `home/default.nix`
- [ ] Run `just check` and `just rebuild`
- [ ] Test in Kitty and Firefox
- [ ] Iterate on shortcut set
