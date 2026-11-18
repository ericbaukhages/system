---
title: "Change Provenance Implementation Options"
type: research
status: proposed
created: 2026-11-17
updated: 2026-11-17
tags: [git, provenance, implementation, signing, agents]
---

# Change Provenance Implementation Options

This document compares concrete ways to implement the three-tier provenance
model and proposes a combined workflow.

## Option 1: Agent-specific Git signing identities

**Idea:** Give the agent its own SSH key, register it as a GitHub signing key on
a bot account, and let the agent sign its commits.

```bash
GIT_AUTHOR_NAME="opencode-agent"
GIT_AUTHOR_EMAIL="agent@example.com"
GIT_COMMITTER_NAME="opencode-agent"
GIT_COMMITTER_EMAIL="agent@example.com"
GIT_SSH_COMMAND="ssh -i ~/.ssh/agent_signing_key.pub -o IdentitiesOnly=yes"
git commit -S -m "feat: ..." -m "Assisted-by: opencode-go/kimi-k2.7-code"
```

**Pros:**
- GitHub shows the commit as verified and attributed to the bot account.
- Clear separation from the human author.

**Cons:**
- The private key must be available to the agent process. If it lives on disk,
  it is a new secret to protect.
- The current workstation signs with 1Password, which requires biometric
  approval for every signature. An unattended agent cannot use 1Password
  signing without human presence.
- GitHub verification does not record *which* model or session produced the
  commit; trailers are needed for that.

**Verdict:** Useful, but only if the agent key is stored at least as securely as
other machine credentials and rotated frequently.

## Option 2: Re-authoring / re-signing while preserving the original commit

**Idea:** The agent creates an unsigned commit. After review, the human rebases
or amends it and signs the rewritten commit with the human key. The original
commit hash is recorded in the new message.

```
feat: add remote access docs

Original-commit: abc123...

Signed-off-by: Human <human@example.com>
```

**Pros:**
- Simple; uses only Git and the human signing key.

**Cons:**
- Rewriting history changes commit hashes and breaks signature chains.
- The agent’s original authorship is harder to follow.
- Re-signing a stack of commits is tedious.

**Verdict:** Acceptable for single commits, but not the primary design because
it hides the original provenance.

## Option 3: Signed attestations that reference the original commit/tree

**Idea:** Do not rewrite the agent commit. Instead, attach signed in-toto
attestations that name the commit/tree as the subject.

Example machine-verification attestation (simplified):

```json
{
  "_type": "https://in-toto.io/Statement/v1",
  "subject": [
    {
      "name": "system",
      "digest": { "gitCommit": "abc123..." }
    }
  ],
  "predicateType": "https://in-toto.io/attestation/test-result/v0.1",
  "predicate": {
    "result": "PASSED",
    "passedTests": ["nix flake check", "just check"],
    "configuration": { "nixos-version": "26.05" },
    "timestamp": "2026-11-17T12:00:00Z"
  }
}
```

Example human-authorization attestation:

```json
{
  "_type": "https://in-toto.io/Statement/v1",
  "subject": [
    { "name": "system", "digest": { "gitCommit": "abc123..." } }
  ],
  "predicateType": "https://in-toto.io/attestation/human-review/v0.1",
  "predicate": {
    "result": "PASSED",
    "reviewLink": "https://github.com/.../pull/123",
    "timestamp": "2026-11-17T13:00:00Z"
  }
}
```

**Pros:**
- Original commit remains untouched.
- Multiple independent claims can attach to the same commit.
- Standard tooling: in-toto, Sigstore, GitHub Artifact Attestations.

**Cons:**
- Attestations must be stored and distributed (Git notes, GitHub attestations,
  OCI registry, or a separate artifact store).
- Verifiers must know where to fetch them.

**Verdict:** This is the preferred approach.

## Option 4: Git trailers, notes, or refs

**Idea:** Embed provenance directly in Git.

- **Trailers** in the commit message: `Assisted-by:`, `Verified-by:`,
  `Original-commit:`. Trailers travel with the commit but are not signed
  separately.
- **Git notes** (`refs/notes/provenance`): attach blobs to commits without
  changing commit hashes. Notes can be signed as separate objects.
- **Signed tags**: `git tag -s reviewed/v1.0 abc123...`.

**Pros:**
- No external infrastructure.
- Signed tags are widely understood.

**Cons:**
- Notes and tags can be forgotten or not fetched by default.
- Trailers are not independently signed.

**Verdict:** Use trailers and signed tags as lightweight complements to
attestations, not as the only mechanism.

## Option 5: GitHub / forge verification and protection

**Idea:** Rely on GitHub’s verified signatures, branch protection, required
status checks, and merge commits.

- Agent commits signed by a bot key show “Verified.”
- CI status checks provide machine verification.
- A human merge creates a GitHub-signed merge commit.

**Pros:**
- Uses existing GitHub capabilities.
- No custom tooling for the forge side.

**Cons:**
- GitHub’s merge commit is signed by GitHub, not the human’s personal key.
- Squash/rebase merges rewrite the branch and drop agent signatures unless the
  human re-signs locally.
- Ties the workflow to GitHub.

**Verdict:** Use GitHub as a deployment and display layer, but keep portable
attestations as the source of truth.

## Proposed combined workflow

For this repository:

1. **Agent produces a commit** with:
   - `author` set to the agent/bot identity.
   - `Assisted-by: opencode-go/<model>` trailer (existing convention).
   - Optional `OpenCode-Session: <session-id>` trailer.
   - The commit may be unsigned, or signed with a dedicated agent key if one is
     added later.

2. **CI runs independent verification** on the pushed branch and produces an
   in-toto attestation. Store it as a GitHub Artifact Attestation or in
   `refs/notes/provenance`.

3. **Human reviews** the diff plus the attestation.

4. **Human endorses** by either:
   - pushing a signed tag (`git tag -s reviewed/<branch>-<date> <commit>`), or
   - adding a signed human-review attestation.

5. **Merge** using a merge commit so the original agent commit and CI checks
   remain visible and signed.

## Key management outline

| Key | Storage | Use | Rotation |
|-----|---------|-----|----------|
| Human signing key | 1Password SSH agent | Signed tags/attestations | Manual, on compromise |
| Agent signing key (optional) | 1Password or encrypted key file in a secret store | Agent commits | Frequent, scoped per repo |
| CI verifier identity | GitHub Actions OIDC / Sigstore | Machine attestations | Managed by GitHub |

The human personal signing key **never** leaves 1Password and is **never**
copied onto the agent’s filesystem.

## Tooling candidates

| Purpose | Tool |
|---------|------|
| SSH commit signing | Git 2.34+ with `gpg.format=ssh` [GitHub SSH signing docs][gh-ssh] |
| 1Password signing | `op-ssh-sign` [1Password SSH signing][1p-sign] |
| Attestation format | in-toto Statement + predicate [in-toto attestation][in-toto] |
| CI signing | GitHub Artifact Attestations (`actions/attest`) [Artifact attestations][gh-attest] |
| Keyless commit signing | Sigstore Gitsign [Gitsign docs][gitsign] |

## Open questions

1. Should the agent signing key be in 1Password with an approval policy, or a
   separate file-based key with restricted permissions?
2. Which attestation storage is simplest for this repository: GitHub Artifact
   Attestations, Git notes, or signed tags?
3. Do we want to require agent-signed commits, or start with unsigned agent
   commits plus human endorsement?

[gh-ssh]: https://docs.github.com/en/authentication/managing-commit-signature-verification/telling-git-about-your-signing-key
[1p-sign]: https://www.1password.dev/ssh/git-commit-signing
[in-toto]: https://github.com/in-toto/attestation
[gh-attest]: https://docs.github.com/en/actions/concepts/security/artifact-attestations
[gitsign]: https://docs.sigstore.dev/cosign/signing/gitsign/
