---
title: "OpenCode Remote Architecture"
type: reference
status: proposed
created: 2026-11-17
updated: 2026-11-17
tags: [opencode, architecture, security, remote]
---

# OpenCode Remote Architecture

This document maps the components, trust boundaries, and decision trade-offs
for monitoring and controlling OpenCode sessions from another device.

## Components

```
┌─────────────────────────────────────────────────────────────┐
│                      Workstation (t490s)                    │
│  ┌─────────────────┐     ┌───────────────────────────────┐  │
│  │ OpenCode server │────▶│ sessions / config / creds /   │  │
│  │ (background)    │     │ permissions / tool execution    │  │
│  └────────┬────────┘     └───────────────────────────────┘  │
│           │ HTTP + Basic auth / cookie                      │
│           │                                                 │
│  ┌────────┴────────┐      ┌────────────────┐                │
│  │   Local TUI     │      │  1Password     │                │
│  │   / CLI         │      │  SSH agent     │                │
│  └─────────────────┘      └────────────────┘                │
└─────────────────────────────────────────────────────────────┘
           │
           ▲ Tailscale / LAN / tunnel
┌─────────────────────────────────────────────────────────────┐
│                   Remote device (phone / laptop)            │
│  ┌──────────────┐    ┌──────────────────┐                   │
│  │ OpenCode Web │ or │ OpenCode Mobile  │                   │
│  │   (PWA)      │    │     (app)        │                   │
│  └──────────────┘    └──────────────────┘                   │
└─────────────────────────────────────────────────────────────┘
```

## Data flow

1. The background service starts automatically (or via `opencode service start`).
2. Sessions, credentials, and permissions live in the server process.
3. Local and remote clients authenticate with the same password and cookie.
4. A remote client can list sessions, view history, send prompts, approve
   permissions, and interrupt execution exactly like the local TUI.
5. Tool execution, file writes, shell commands, and Git operations run as the
   workstation user.

## Authentication and authorization

- Username defaults to `opencode`; password is set with
  `opencode service set password` or `OPENCODE_SERVER_PASSWORD`.
- Pairing links are single-use and expire in five minutes.
- Cookies last 30 days.
- Changing the password invalidates all sessions.
- Permission prompts and agent rules are enforced server-side, so they apply
  equally to remote clients.

## Decision matrix

| Approach | Effort | Security | Completeness | Recommendation |
|----------|--------|----------|--------------|----------------|
| A. Native OpenCode Web / Mobile | Low | Good with Tailscale | Full session control | **Primary** |
| B. OpenCode server over Tailscale | Low | Good | Same as A; just the network path | **Primary** |
| C. Small custom API/SDK dashboard | Medium | Same as server; adds code | Must reimplement UI and event handling | Avoid for routine use |

There is no need to build a custom orchestration platform. The native clients
already provide session inventory, live events, permission handling, and
conversation continuity.

## Threat model

| Threat | Likelihood | Impact | Mitigation |
|--------|------------|--------|------------|
| Stolen pairing link | Low | High (server access) | Short expiry, single use, rotate password if leaked |
| Stolen cookie | Medium | High | Rotate password; keep session duration reasonable |
| Tailnet compromise | Low | High | Tailscale ACLs, device posture, MFA on Tailscale account |
| OpenTunnel URL leaked | Medium | High | Treat as public; rely on strong password; prefer Tailscale |
| Server bound to `0.0.0.0` on untrusted network | Medium | High | Bind to loopback; expose only through Tailscale |
| Remote client approves dangerous permission | Medium | High | Human remains responsible; do not enable `--auto` for remote agents |
| Server process compromised | Low | Critical | Server runs as user; follow workstation hardening |

## Operational notes

- The background service must keep running while you are away. Use the standard
  `opencode service` mechanism; do not run an ad-hoc `opencode serve` unless you
  need a dedicated port.
- For unattended agents, ensure the workstation does not sleep or suspend.
- Keep OpenCode updated through the Nix-managed package in `home/opencode.nix`.
- Do not expose the service to the public internet without a clear operational
  need.

## Relationship to change provenance

Remote sessions are part of the provenance story: an agent running in an
OpenCode session can produce Git commits, and the session ID/model/agent can be
recorded in commit trailers or external attestations. See
`docs/architecture/remote-development-and-trust.md` for the integrated design.

## Open questions

1. Should the server password be managed in 1Password and injected at login, or
   set manually and rotated periodically?
2. Do we want Tailscale ACL tags restricting the workstation port to specific
   devices?
3. Should remote permission approvals require an extra confirmation step or
   time-of-day policy?
