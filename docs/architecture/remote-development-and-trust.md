---
title: "Remote Development and Change Trust"
type: research
status: proposed
created: 2026-11-17
updated: 2026-11-17
tags: [architecture, opencode, provenance, remote, security]
---

# Remote Development and Change Trust

This document ties together two research streams:

1. **Remote OpenCode management** — how to monitor and steer agent sessions from
   another device.
2. **Change provenance and trust** — how to distinguish agent-produced,
   machine-verified, and human-authorized changes.

It explains how the two systems can share security boundaries and how provenance
can flow from a remote agent session all the way to a human endorsement.

## Executive summary

- OpenCode 2 already provides the remote-management capability we need. A
  background service exposes sessions, events, permissions, prompts, and
  execution control through a password-protected HTTP API. Native clients (web
  PWA, mobile app) consume this API.
- The recommended remote path is **OpenCode Web over Tailscale**. This keeps the
  service off the public internet, requires no new infrastructure, and uses the
  existing 1Password and SSH workflows on the workstation.
- Change trust can be built with **agent authorship trailers + CI in-toto
  attestations + human-signed endorsement**, without rewriting history or
  exposing the human personal signing key.
- The two systems meet at the commit: an OpenCode session ID can be recorded in
  a commit trailer, CI can verify the resulting tree independently, and a human
  can review and endorse the exact commit remotely.

## Recommended architecture for remote OpenCode management

See `docs/opencode/session-management.md`,
`docs/opencode/remote-access.md`, and `docs/opencode/architecture.md` for
details.

### Components

| Component | Role | Choice |
|-----------|------|--------|
| OpenCode server | Owns sessions and executes tools | Background service (`opencode service`) |
| Network access | Private reachability from phone | Tailscale |
| Remote client | View sessions, approve prompts, continue chats | OpenCode Web (browser/PWA) |
| Authentication | Server access control | `opencode service set password` + pairing links |

### Why this is enough

The native API already provides:

- full session inventory (`/api/session`, `/api/session/active`)
- live events (`/api/event`)
- permission and form replies
- prompts, commands, interrupts, and shell access
- child-session (subagent) visibility

No custom dashboard is required.

## Recommended architecture for change provenance

See `docs/change-provenance/overview.md`,
`docs/change-provenance/trust-model.md`,
`docs/change-provenance/implementation-options.md`, and
`docs/change-provenance/security-and-threat-model.md` for details.

### Components

| Tier | Mechanism | Storage |
|------|-----------|---------|
| Agent-produced | Bot author identity + `Assisted-by:` + optional `OpenCode-Session:` trailers | In the commit object |
| Machine-verified | CI check suite + in-toto attestation | GitHub Artifact Attestation or Git notes |
| Human-authorized | Signed tag or signed human-review attestation | Git refs / attestations |

### Why attestations instead of re-signing

Attestations reference the original commit/tree without rewriting it. This
preserves agent authorship, keeps signatures meaningful, and lets multiple
independent claims attach to the same change.

## Shared security boundaries

Both systems rely on the same workstation and the same network controls:

| Boundary | Remote management | Change provenance |
|----------|-------------------|-------------------|
| Workstation | Server must stay running and reachable | Agent commits and CI checks originate here |
| Tailscale | Remote clients enter the tailnet | Not directly used, but protects push/CI access |
| 1Password | Not used by server auth | Human signing key lives here; must not leave |
| GitHub | Not used | Hosts bot signing keys, branch protection, attestations |
| Agent key | Could authenticate to server? No; server uses password | Could sign agent commits if added |

The biggest shared risk is **workstation compromise**. If an attacker controls
the workstation, they can both abuse OpenCode sessions and forge agent commits.
That risk is mitigated by workstation hardening, not by these workflows.

## Integration opportunities

### 1. Remote session identity → commit authorship

OpenCode sessions have stable IDs (`ses_...`). A session can record its ID in a
commit trailer:

```
feat: add remote access docs

Assisted-by: opencode-go/kimi-k2.7-code
OpenCode-Session: ses_e13a58634ffeg56JzoERspVJuK
```

This links the remote session to the original commit. It is not a cryptographic
proof, but it is a strong audit link.

**Limitation:** The remote *client* (phone/browser) is not recorded by Git.
Only the OpenCode server knows which client sent a prompt. The server could be
extended to log client IP/User-Agent, but that is not built-in.

### 2. Agent session → verifiable provenance metadata

OpenCode can export a session (`opencode session export` or
`/api/experimental/session/{id}/export`). The export contains the transcript,
tool calls, and model used. This can be stored as evidence, but it is not
independently verifiable because the server controls it.

For verifiable provenance, the independent CI verifier re-runs checks and
produces a signed attestation. The agent session metadata is supplementary
context, not the proof.

### 3. Machine verification independent of the agent

GitHub Actions checks out the branch and runs:

- `nix flake check`
- `just check`
- lint / type checks
- any security scans

It then creates an in-toto attestation with the commit as subject. This runs in
a separate environment from the agent, satisfying the independence requirement.

### 4. Human authorizes a commit remotely without exposing the personal key

**Recommended approach:**

- Human reviews the diff and the CI attestation from the OpenCode Web client
  over Tailscale.
- Human performs the cryptographic endorsement from a trusted workstation
  (either the same one, reached remotely, or after returning to it).
- The endorsement is a signed tag or attestation using the human’s 1Password
  protected key.

**If endorsement must happen from the remote device:**

- Use GitHub’s merge button. The resulting merge commit is signed by GitHub’s
  web-flow key and records the human’s approval in the PR timeline. This does
  not expose the personal signing key, but it is also not a personal signature.

**What we do not recommend:**

- Copying the human private key to a phone or remote server.
- Letting the agent use the human signing key unattended.
- Using a cloud signing service that would require new infrastructure.

### 5. Preserving the complete chain

The complete chain, from agent session to human endorsement, can be:

1. **Agent session** produces a commit with session/model trailers.
2. **Original commit** is pushed and preserved in a merge commit.
3. **CI verifier** produces an attestation naming the commit/tree.
4. **Human** reviews and adds a signed tag/attestation.
5. **Merge commit** ties the original commit, CI status, and approval together.

A verifier can later reconstruct:

```
git log --format='%H %an <%ae> %G?'   # agent authorship and signature status
git tag -v reviewed/...               # human endorsement
cat .provenance/<commit>.json         # machine verification evidence
```

## Security and threat model (combined)

| Threat | Control |
|--------|---------|
| Remote OpenCode server exposed to the internet | Use Tailscale; bind to loopback; rotate password |
| Stolen pairing link / cookie | Short expiry, single use, password rotation |
| Agent commits malicious code | Dedicated bot identity; branch protection; human endorsement |
| Human signing key exposed | 1Password SSH agent; never on disk or agent filesystem |
| CI attestation forged | Reusable workflow; OIDC identity; minimal permissions |
| History rewritten to hide provenance | Merge commits; signed tags; disable force-push |
| Workstation compromised | Workstation hardening (out of scope of this proposal) |

The combined trust assumption is:

- The OpenCode server is honest about session state.
- The CI verifier runs independently and reports true results.
- The human review is genuine before endorsement.
- 1Password protects the human signing key.

## Implementation roadmap

### Phase 0: Research (this document)

- [x] Survey OpenCode 2 remote/session API.
- [x] Survey Git signing, attestations, and GitHub verification.
- [x] Define trust model and integration points.
- [x] Record verified local API behavior.

### Phase 1: Remote access (no code changes)

1. Confirm Tailscale is running on workstation and phone.
2. Set a strong OpenCode server password.
3. Test `opencode pair --url https://t490s.<tailnet>.ts.net` from the phone
   browser.
4. Document the tested steps in `docs/opencode/remote-access.md`.

### Phase 2: Agent authorship (lightweight)

1. Decide whether to introduce a dedicated bot GitHub account and agent signing
   key, or keep agent commits unsigned with trailers only.
2. Add `OpenCode-Session:` trailer convention to the commit skill if desired.
3. Update `AGENTS.md` with the provenance convention.

### Phase 3: Machine verification

1. Ensure the existing CI runs `nix flake check` / `just check`.
2. Add a reusable workflow that emits an in-toto attestation (e.g., via
   `actions/attest`) for the checked-out commit.
3. Store attestations as GitHub Artifact Attestations or in a Git notes ref.

### Phase 4: Human endorsement

1. Decide on endorsement mechanism: signed tag, signed attestation, or GitHub
   merge-commit approval.
2. If using personal signatures, ensure the human can sign from a trusted
   workstation.
3. Update branch protection to require the endorsement evidence.

### Phase 5: Integration

1. Link session ID to commits via trailer.
2. Add a verification helper script (`just verify-provenance`?) that checks
   commit signature, CI attestation, and human endorsement for a given ref.

## Outstanding decisions requiring human input

1. **Remote access:** Should we test and enable Tailscale-based OpenCode Web
   access now, or keep remote access disabled until a specific need arises?
2. **Agent signing key:** Do we want to create a dedicated bot GitHub account
   and agent signing key, or rely on unsigned agent commits plus later human
   endorsement?
3. **Human endorsement mechanism:** Signed tag, signed in-toto attestation, or
   GitHub merge-commit approval?
4. **Attestation storage:** GitHub Artifact Attestations, Git notes, or a
   repository-local provenance directory?
5. **Branch protection:** Should agent-produced changes be required to merge via
   merge commit, and should force-push be disabled on `main`?
6. **Session trailer:** Should the commit skill record the OpenCode session ID
   in every assisted commit?

## References

- OpenCode Web / remote access: https://opencode.ai/v2/docs/cli/web
- OpenCode API reference: https://opencode.ai/v2/docs/api
- OpenCode client / service: https://opencode.ai/v2/docs/build/client
- GitHub commit signature verification: https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification
- GitHub Artifact Attestations: https://docs.github.com/en/actions/concepts/security/artifact-attestations
- in-toto attestation framework: https://github.com/in-toto/attestation
- 1Password SSH commit signing: https://www.1password.dev/ssh/git-commit-signing
