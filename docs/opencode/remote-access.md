---
title: "OpenCode Remote Access"
type: research
status: proposed
created: 2026-11-17
updated: 2026-11-17
tags: [opencode, remote, tailscale, security]
---

# OpenCode Remote Access

This document compares the network paths for reaching an OpenCode 2 server from
a phone or another computer, and recommends the simplest safe configuration for
our environment.

## Goal

Leave agents running on the workstation and be able to see what they are doing,
respond to permission prompts, and continue a session from a mobile browser or
the OpenCode mobile app.

## Native remote clients (facts)

OpenCode ships with two first-class remote clients:

- **OpenCode Web** — a browser/PWA served by the same server as the TUI. Access
  it via `opencode pair`.
- **OpenCode Mobile** — iOS (TestFlight) and Android apps that act as a remote
  for the workstation server [OpenCode Mobile][oc-mobile].

Both clients talk to the same background service and show the same sessions.

## Pairing model (fact)

```bash
opencode pair
```

Prints a one-time link and a QR code. Links work once, expire after five
minutes, and sign the browser/app in with a session cookie. Sessions last 30
days; changing the server password signs every session out [OpenCode Web
 docs][oc-web].

For a public or custom URL:

```bash
opencode pair --url https://your-opencode-host.example
```

For OpenTunnel (public internet):

```bash
opencode pair --remote
```

The first `--remote` run requires an explicit confirmation because it exposes
the server to the internet [OpenCode Web docs][oc-web].

## Network routes compared

| Route | Best for | Exposure |
|-------|----------|----------|
| Same LAN / Wi-Fi | At home or trusted office | Private network only |
| Tailscale | Phone + workstation, no public exposure | Tailnet only |
| SSH local forward | Laptop with SSH access | Loopback via SSH |
| OpenTunnel (`--remote`) | Temporary access from anywhere | Public HTTPS URL |
| Cloudflare Tunnel | Stable public HTTPS without port forwarding | Public HTTPS URL |
| OpenCode Cloud Link | Managed mobile access | Managed tunnel (subscription) |

[OpenCode Mobile remote access comparison][oc-mobile-remote].

## Recommended configuration: Tailscale + OpenCode Web

Given that Tailscale is already part of the environment, the simplest viable
design is:

1. Keep the OpenCode background service bound to `127.0.0.1` on the workstation.
2. Expose that port inside the tailnet with `tailscale serve`, or bind the
   service to the workstation's Tailscale IP and restrict access with Tailscale
   ACLs.
3. Set a strong server password:
   ```bash
   opencode service set password "<long-generated-secret>"
   opencode service restart
   ```
4. On the phone, open a browser and navigate to the Tailscale origin, then run
   `opencode pair --url https://t490s.<tailnet-name>.ts.net` from the
   workstation to create a one-time link.

This avoids public internet exposure, router port forwarding, and extra
infrastructure. It also preserves the existing 1Password and SSH workflows
because the server still runs on the workstation.

## Configuration reference

```bash
# Show current service address
opencode service status

# Set a fixed password (recommended)
opencode service set password "..."

# Use a fixed port (optional)
opencode service set port 49374

# Bind to every interface only on a trusted LAN
opencode service set hostname 0.0.0.0

# Reset to loopback when leaving the LAN
opencode service set hostname 127.0.0.1

# Restart to apply changes
opencode service restart
```

For a standalone server (e.g., under systemd):

```bash
OPENCODE_PASSWORD="..." opencode serve --hostname 127.0.0.1 --port 4096
```

[OpenCode server docs][oc-server].

## Security analysis

| Control | What it does | Limitation |
|---------|--------------|------------|
| Basic auth (`OPENCODE_SERVER_PASSWORD`) | Password required for every client | Single shared password; rotation revokes all sessions |
| One-time pairing links | Short-lived, single-use authentication | Must be generated on the server and transmitted safely |
| 30-day cookie sessions | Convenient reconnection | Lost/stolen cookie grants server access until password is rotated |
| Tailscale | Private layer-3 network | Compromised tailnet member can reach the port; still need OpenCode password |
| OpenTunnel TLS | Traffic is TLS-terminated locally; relay sees only SNI | URL is public; anyone with the URL can connect; application auth is the only gate [OpenTunnel README][ot-readme] |
| `0.0.0.0` binding | Lets any reachable interface connect | Dangerous on untrusted networks; use Tailscale instead |

### Key rules

- Do not bind the service to `0.0.0.0` unless the network is trusted.
- Treat an OpenTunnel URL as unauthenticated public exposure; the password is
  the only gate.
- Rotate the server password if a phone is lost or a pairing link is shared
  accidentally.
- Do not bypass authentication or disable permission prompts for remote access.

## Verified and unverified behavior

| Claim | Status | Evidence |
|-------|--------|----------|
| Background service runs on `127.0.0.1:49374` | Verified | `opencode service status` |
| `opencode api session.list` works locally | Verified | direct test |
| `GET /api/session/active` works locally | Verified | direct test |
| Web UI loads and pairs from a phone over Tailscale | Not verified | requires phone + tailnet test |
| Mobile app pairs over Tailscale | Not verified | requires app install |
| OpenTunnel `--remote` behavior | Not verified | documented upstream only |

## Recommendation

Adopt **OpenCode Web over Tailscale** as the default remote-access path. Do not
use `--remote` or public tunnels for routine work. Re-evaluate OpenCode Cloud
Link only if Tailscale becomes inconvenient on mobile.

[oc-web]: https://opencode.ai/v2/docs/cli/web
[oc-server]: https://opencode.ai/v2/docs/server
[oc-mobile]: https://opencode.ai/mobile
[oc-mobile-remote]: https://getopencode.app/docs/remote-access
[ot-readme]: https://github.com/anomalyco/opentunnel/blob/master/README.md
