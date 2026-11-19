---
title: "Agent workflow with worktrees"
type: reference
status: draft
created: 2026-11-18
updated: 2026-11-18
tags: [opencode, worktrees, workflow, agents, git]
---

# Agent workflow with worktrees

Agents working on this repository should use OpenCode-managed worktrees and
pull requests, not the main working directory.

## Why worktrees

- **Isolation:** the `main` working directory and other agent sessions stay untouched.
- **Parallel work:** multiple agents can work on different branches at the same time.
- **Clean history:** every change arrives on `main` through a merge commit that
  preserves the original agent commit and its trailers.

## Creating a worktree

Use the OpenCode worktree tool. The worktree is created under
`~/.local/share/opencode/worktree/<session>/<name>` and checked out from the
current branch. Name it after the task or topic, for example:

- `macos-super-key`
- `opencode-workflow-docs`

After creating the worktree, move the session into it so tools operate there.

## Branch naming

Create a branch in the worktree with the same name as the worktree, prefixed
with `agent/`:

```bash
git checkout -b agent/macos-super-key
```

This makes agent branches easy to identify on the remote.

## Commit conventions

- Author: use the bot/agent identity, not the human owner.
- Include `Assisted-by: opencode-go/<model>` in every assisted commit.
- Include `OpenCode-Session: <session-id>` when the session ID is known.
- Sign commits with the bot signing key if one is configured.

## No direct changes to `main`

Agents must not commit directly to `main` or push to it. The flow is:

1. Work in the worktree on `agent/<topic>`.
2. Push the branch to the remote.
3. Open a pull request.
4. Human reviews and merges with a merge commit.

## Finishing

After the PR is merged, the worktree can be removed. The main working directory
remains the source of truth for long-lived state.

## Relationship to provenance

Worktrees make the provenance chain straightforward: the agent commit is
preserved in the merge commit, the PR records human approval, and CI checks run
on the branch before merge.
