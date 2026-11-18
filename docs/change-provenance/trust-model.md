---
title: "Change Provenance Trust Model"
type: research
status: proposed
created: 2026-11-17
updated: 2026-11-17
tags: [git, provenance, trust, signing, agents]
---

# Change Provenance Trust Model

This document defines the trust roles, signature semantics, and invalidation
rules for the tiered provenance system.

## Roles

| Role | Identity form | What they do |
|------|---------------|--------------|
| **Agent author** | `Agent Name <agent@example.com>` or bot account | Produces the original change, writes files, runs tests, creates commits |
| **Machine verifier** | CI service account, reusable workflow, or local check tool | Re-runs checks independently and records evidence |
| **Human endorser** | Human owner/reviewer with a personal signing key registered in GitHub/1Password | Reviews the change and evidence and cryptographically endorses it |

Each role uses a distinct signing identity. No role signs for another.

## Tier 1: Agent-produced

- The commit `author` reflects the agent or bot that did the work, not the
  human owner.
- A trailer records the assisting model, matching the existing convention in
  this repository:
  ```
  Assisted-by: opencode-go/kimi-k2.7-code
  ```
- Optionally, an agent-specific SSH signing key can sign the commit. The public
  key is registered as a **signing key** on a dedicated bot GitHub account.
- The original commit object and its hash are preserved. Any later endorsement
  references this original commit by hash.

## Tier 2: Machine-verified

- Verification runs in an environment independent of the agent, typically
  GitHub Actions.
- Evidence is a signed attestation (in-toto statement) that references the
  commit and/or tree hash and lists:
  - check names and results (tests, lint, types, security scans)
  - tool and environment versions
  - timestamp
  - verifier identity
- The attestation is stored as a GitHub Artifact Attestation, a Git note, or a
  signed file in a provenance ref (e.g., `refs/notes/provenance`).
- Verification is **not** a signature on the commit itself. It is a signed claim
  that the commit passed a defined check suite at a specific time.

## Tier 3: Human-authorized

- The human reviews the diff, the agent attribution, and the machine
  verification evidence.
- Authorization is expressed as one of:
  - a signed Git tag on the verified commit (`git tag -s reviewed/...`)
  - a signed in-toto attestation with predicate type `human-review`
  - a GitHub pull-request approval plus merge, where GitHub signs the merge
    commit with its web-flow key (this does not use the human’s personal key)
- The human’s personal signing key stays in 1Password and is never copied to an
  agent-accessible filesystem.

## Signature semantics

| Statement | Meaning | Does not mean |
|-----------|---------|---------------|
| Commit is signed by agent key | Agent identity created this exact commit | The code is correct or safe |
| CI attestation is valid | Defined checks passed against this tree | All possible bugs are absent |
| Human signed tag/attestation | A trusted human reviewed and approved | The human wrote the code |

Git commit signatures cover the entire commit object, including the tree hash,
parent hashes, author, committer, and message. Any rewrite (rebase, amend,
squash) changes the object hash and invalidates the signature.
[Git commit object docs][git-commit].

## Invalidation rules

1. **Rebase or amend** of an agent commit creates a new commit object. The old
   agent signature no longer applies. The new commit must be signed by whoever
   performed the rewrite.
2. **Any change to a verified tree** invalidates verification evidence for the
   old tree. The verifier must re-run against the new tree.
3. **Human endorsement** applies only to the exact tree/commit it names. A
   later rebase requires a new endorsement.
4. **Expiration of a signing key** does not retroactively invalidate previously
   verified commits if the host uses persistent verification records
   [GitHub persistent verification][gh-persistent].

## Branch protection expectations

For repositories using this model:

- Require signed commits on protected branches.
- Allow merge commits so that agent and verifier signatures remain visible in
  history. Squash/rebase merges create new commits and drop or replace
  signatures unless re-signed locally.
- Require status checks from the independent verifier.
- Consider requiring a human-approved merge for agent-produced changes.

## Open questions

1. Should agent commits be signed by an agent key, or remain unsigned and rely
   on author/trailers plus later verification?
2. Should human endorsement be a signed tag, a signed attestation, or a
   protected merge commit?
3. Should the verifier re-run on every push, or only when requested by a human?

[git-commit]: https://git-scm.com/docs/git-commit#_commit_information
[gh-persistent]: https://github.blog/changelog/2024-11-12-persistent-commit-signature-verification-now-in-public-preview/
