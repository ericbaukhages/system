# Documentation index

This directory holds notes, plans, research, and reference material for the
system flake. Each file includes YAML front matter with `type`, `status`, and
tags so we can track what is inspiration, what is a worked-out plan, and what
has already been implemented.

## Status legend

| Status | Meaning |
|---|---|
| `draft` | Early idea or working text, not yet finalized. |
| `proposed` | A concrete proposal or plan waiting for work to start. |
| `in-progress` | Currently being worked on. |
| `implemented` | The plan has been built; the doc is now a record. |
| `stable` | A reference or decision we are actively following. |
| `abandoned` | Decided not to pursue. |

## Docs by category

### Plans

| Doc | Status | Tags |
|---|---|---|
| [Homelab migration plan](plans/homelab-migration-plan.md) | implemented | nixos, homelab, x250, t490s, caddy, podman, tailscale |
| [macOS-style Super key](plans/macos-style-super-key.md) | proposed | nixos, gnome, keyd, input, keyboard, macos |
| [CLI tools to try](plans/cli-tools-to-try.md) | in-progress | cli, tools, nix, home-manager |

### Research / inspiration

| Doc | Status | Tags |
|---|---|---|
| [The Dendritic Pattern for Nix Configurations](inspiration/dendritic-pattern.md) | proposed | nix, dendritic, flake-parts, import-tree, architecture |

### Reference

| Doc | Status | Tags | Notes |
|---|---|---|---|
| [Development Workflow](reference/development-workflow.md) | abandoned | ai, workflow, collaboration, conventions | Skill removed from OpenCode config on 2026-09-19; doc kept as historical reference. |

## Adding a new doc

1. Decide whether it is a `plan`, `research`, `reference`, or `decision`.
2. Place it in the matching folder.
3. Add YAML front matter at the very top of the file:

   ```yaml
   ---
   title: "..."
   type: plan
   status: proposed
   created: YYYY-MM-DD
   updated: YYYY-MM-DD
   tags: [tag1, tag2]
   ---
   ```

4. Update this README so the index stays current.
