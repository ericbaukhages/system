---
title: "Change Provenance Overview"
type: research
status: proposed
created: 2026-11-17
updated: 2026-11-17
tags: [git, provenance, signing, agents, trust]
---

# Change Provenance Overview

This document introduces the trust and provenance model for changes produced by
coding agents. It is the starting point for the change-provenance research
stream.

## Core question

How can we distinguish, in a verifiable way:

1. Code an agent produced.
2. Code a machine independently verified.
3. Code a human reviewed and explicitly authorized.

## Three tiers

| Tier | Actor | Guarantee | Recorded evidence |
|------|-------|-----------|-------------------|
| **Agent-produced** | Coding agent (OpenCode, subagent, CI bot) | Identity of the agent and the model that produced the change | Commit author/trailers, session/model metadata, optional agent signature |
| **Machine-verified** | Independent verifier (CI, local check suite) | Checks ran and passed against a specific tree | Signed attestation listing checks, tool versions, inputs, and the tree/commit hash |
| **Human-authorized** | Human reviewer/owner | A person reviewed the change and evidence and endorsed it | Human signature or signed attestation covering the final tree/commit |

A valid signature proves **identity and authorization**, not correctness. It
says “this identified party signed this exact object,” not “the code is safe.”
[GitHub commit signature verification docs][gh-verify].

## Key design principles

1. **Preserve agent authorship.** The original commit and its author/trailers
   remain visible. Human endorsement must not rewrite history in a way that
   hides the agent.
2. **Separate keys by role.** Agent signing keys, verifier keys, and the human
   signing key are different. The human personal signing key never leaves
   1Password.
3. **Record evidence, not just outcomes.** Machine verification should capture
   what was checked, by whom/what, with which tools and versions, against which
   commit/tree, and when.
4. **Invalidate on change.** Any change to the verified tree (amend, rebase,
   squash, cherry-pick) invalidates prior verification evidence. The verifier
   must re-run, or the evidence must reference the new tree explicitly.
5. **Avoid unnecessary infrastructure.** Prefer Git, GitHub, SSH signing, and
   in-toto/SLSA-style attestations over custom servers.

## Scope

In scope:

- Agent identity in commits.
- Independent CI verification and evidence.
- Human endorsement via signing or attestations.
- Preservation of original commit provenance.

Out of scope for the research phase:

- Modifying existing Git hooks, signing configuration, or branch protections.
- Introducing a custom certificate authority or signing service.
- Replacing 1Password as the human key store.

## Relationship to remote development

Remote OpenCode sessions can produce commits. Recording the OpenCode session ID,
agent, and model in commit trailers links the remote work to the resulting
change. Independent CI verification and human endorsement can then happen
asynchronously, without requiring the human to be at the workstation.

[gh-verify]: https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification
