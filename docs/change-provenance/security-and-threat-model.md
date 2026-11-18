---
title: "Change Provenance Security and Threat Model"
type: research
status: proposed
created: 2026-11-17
updated: 2026-11-17
tags: [git, provenance, security, threat-model, signing]
---

# Change Provenance Security and Threat Model

This document identifies the threats against the tiered provenance system and
the controls that address them.

## Threat actors

| Actor | Capability | Goal |
|-------|------------|------|
| Compromised agent | Can write files, run shell commands, call tools | Push malicious changes under agent identity |
| Compromised workstation user | Can access agent key, sign commits, run CI locally | Forge agent commits or verification evidence |
| Compromised CI | Can produce attestations | Claim malicious commits passed checks |
| External attacker | May steal cookies, keys, or credentials | Impersonate agent, verifier, or human |
| Insider (human) | Can sign with human key | Approve bad changes intentionally |

## Threats and controls

### 1. Agent produces unauthorized commits

- **Control:** Agent commits use a dedicated bot author identity and optional
  agent signing key, not the human identity.
- **Control:** Require human review/endorsement before merging to protected
  branches.
- **Control:** Branch protection rules require signed commits and passing status
  checks.
- **Residual risk:** A compromised agent key can still sign commits; the key
  must be scoped and rotated.

### 2. Human personal signing key is exposed to the agent

- **Control:** The human key stays in 1Password and is accessed only through the
  1Password SSH agent, which requires biometric approval per signature
  [1Password SSH signing][1p-sign].
- **Control:** Agent signing keys and human signing keys are separate.
- **Residual risk:** If the agent is configured to use the human key, every
  agent commit would require the human to be present, defeating unattended
  operation.

### 3. Verification evidence is forged or replayed

- **Control:** Attestations are signed by the CI identity (GitHub Actions OIDC /
  Sigstore) and reference the exact commit/tree hash.
- **Control:** Attestations include timestamps and tool versions.
- **Control:** Verification is invalid if the tree changes.
- **Residual risk:** A compromised CI can sign false attestations. Mitigate by
  making the verifier a minimal, reusable workflow with limited permissions.

### 4. History is rewritten to hide agent provenance

- **Control:** Prefer merge commits so original agent commits remain reachable.
- **Control:** Use signed tags or attestations that name the original commit
  hash.
- **Residual risk:** Force-push can rewrite history; require
  `--force-with-lease` or disable force-push on protected branches.

### 5. Human endorses without reviewing

- **Control:** Require the human to review both the diff and the machine
  verification evidence before signing.
- **Control:** Keep the endorsement action explicit (signed tag or attestation),
  not implicit by merge button alone.
- **Residual risk:** Humans can still make mistakes; the signature proves
  identity, not correctness.

### 6. Remote authorization leaks the human signing key

- **Control:** Remote review happens in OpenCode Web over Tailscale. The actual
  cryptographic endorsement is performed on a trusted workstation, not on the
  remote device.
- **Alternative:** If remote signing is required, use a separate
  lower-assurance endorsement mechanism (e.g., GitHub merge button with web-flow
  signature) and record the merge commit as the human authorization event.
- **Residual risk:** Remote devices may be compromised; avoid storing the human
  signing key on them.

## Key management controls

| Key | Threat | Control |
|-----|--------|---------|
| Human signing key | Theft, misuse | 1Password SSH agent; biometric approval; never on disk |
| Agent signing key | Theft if file-based | Store in 1Password or encrypted secret store; scope to repo; rotate |
| CI verifier identity | Compromised runner | Reusable workflow, minimal permissions, OIDC identity |

## Verification invalidation rules (security rationale)

Any change to a signed object changes its hash, which invalidates signatures
over it. Therefore:

- Rebase, amend, squash, or cherry-pick of an agent commit requires re-signing.
- A changed tree requires new machine verification evidence.
- A changed tree requires new human endorsement.

This follows directly from Git’s object model: commit signatures cover the tree,
parents, author, committer, and message [Git commit internals][git-commit].

## Recommended security properties to enforce

1. Protected branches require signed commits.
2. Protected branches require the independent CI status check.
3. Agent-produced commits are merged via merge commit.
4. Force-push is disabled on protected branches.
5. Human endorsement is recorded before merge.
6. No long-lived signing key is stored in the repository or agent home
   directory.

## Open questions

1. What is the rotation policy for the agent signing key?
2. Should the CI verifier run in a separate, locked-down repository or reusable
   workflow to isolate it from the code it checks?
3. Should we require two human approvals for changes that touch security
   configuration?

[1p-sign]: https://www.1password.dev/ssh/git-commit-signing
[git-commit]: https://git-scm.com/docs/gitcore-tutorial#_the_git_object_database
