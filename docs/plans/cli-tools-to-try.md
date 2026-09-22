---
title: "CLI tools to try"
type: plan
status: in-progress
created: 2026-09-19
updated: 2026-09-21
tags: [cli, tools, nix, home-manager]
---

# CLI tools to try

A running list of command-line tools we want to try, plus their packaging status in this flake.

## Currently adding

_None._

## Added

| Tool | Repo | Version | Status | Notes |
|---|---|---|---|---|
| tuxedo | <https://github.com/webstonehq/tuxedo> | v2026.8.1 | added | Fast keyboard-driven todo.txt TUI. Added via upstream Nix flake overlay. |
| kew | <https://github.com/ravachol/kew> | v4.3.4 | added | Terminal music player. Added via upstream Nix flake overlay. |
| ghgrab | <https://github.com/abhixdd/ghgrab> | v2.0.2 | added | TUI for browsing/downloading files from GitHub, GitLab, Gitea, Codeberg, Forgejo. Added via upstream Nix flake package. |
| leaf | <https://github.com/RivoLink/leaf> | 1.28.2 | added | Terminal Markdown previewer. Added via custom `buildRustPackage` derivation from upstream source. |

## On deck

| Tool | Repo | Status | Notes |
|---|---|---|---|
| lazyrsync | <https://github.com/westpoint-io/lazyrsync> | not packaged | TUI for rsync. No Nix flake; will need a custom `buildRustPackage` derivation. |

## Added / rejected

_None yet._

## How to add a new tool

1. Check if it's already in `nixpkgs` or `nixpkgs-unstable`.
2. If the upstream repo has a `flake.nix`, add it as a flake input and wire in its overlay or package.
3. If it doesn't have a flake, write a custom derivation (usually `rustPlatform.buildRustPackage` for Rust projects).
4. Add the resulting package to `home/packages.nix`.
5. Update this doc with status and any first impressions after using it.

## Sources / inspiration

- The initial tool list came from "Modern CLI Tools You Should Be Using" by [Sin-cy](https://github.com/Sin-cy) on YouTube: <https://www.youtube.com/watch?v=II17TPAb4AQ&t=16s>.
