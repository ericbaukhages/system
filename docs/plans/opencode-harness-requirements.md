---
title: "OpenCode Harness Requirements"
type: plan
status: draft
created: 2026-08-12
updated: 2026-08-12
tags: [opencode, harness, slash-commands, workflow]
---

# OpenCode Harness Requirements

This document collects harness and plugin features that the historical
`development-workflow` skill needed but that cannot be implemented purely inside
a system prompt or skill file. Use it as a reference when evaluating OpenCode
configuration options, writing custom plugins, or filing upstream feature
requests.

> **Note (2026-09-19):** The global `development-workflow` skill was removed
> from OpenCode config. This document is kept as a historical record of the
> features that would have supported it.

## Current workarounds

Until harness support exists, the workflow would have used these fallbacks:

| Desired feature | Current workaround | Limitation |
|-----------------|--------------------|------------|
| Structured mode switch | Natural-language phrase + `.opencode/pairing-mode` file | Requires the human to know the magic phrase; no tab completion or validation feedback. |
| Planning command (`/plan`) | Natural-language request for planning | No standardized output location; plans live in chat history. |
| Config override (`/config-override`) | Natural-language phrase + `.opencode/pairing-mode` file | Ambiguous whether a temporary instruction should persist to the file. |
| Plan artifact storage | Manual `docs/plans/` or `.opencode/notes/` file | AI must offer and human must approve each time; no consistent path convention. |

## Requirements

### 1. Slash command registry

The harness should provide a way to register slash commands from skills or
project configuration.

- Commands must be discoverable (e.g. `/help` or tab completion).
- Commands should be namespaced by skill to avoid collisions
  (e.g. `/workflow mode ai-led`).
- Unrecognized commands must produce a clear error, not be silently treated as
  user text.

### 2. `/workflow mode <mode>`

Switch the current pairing mode explicitly and persist it.

**Behavior:**
- Accept `ai-led`, `balanced`, or `human-led`.
- Validate the value and reject invalid modes with a helpful message.
- Update `.opencode/pairing-mode` if the project uses file-based persistence.
- Confirm the switch to the user, including a one-line summary of what changes.
- Allow an optional `--temp` flag for a switch that applies only to the next
  task or turn and does not persist.

**Example:**

```text
/workflow mode ai-led
```

**Confirmation:**

```text
Switched to ai-led mode. I will implement independently and pause only for
project guardrails and natural checkpoints.
```

### 3. `/plan`

Start or continue a structured planning discussion.

**Behavior:**
- Pause implementation and lead the human through the planning questions:
  - What are we trying to accomplish?
  - What is the current state of the relevant part of the project?
  - What is unclear or missing?
  - Which pairing mode fits best?
- Offer to write a plan artifact to `docs/plans/` or `.opencode/notes/`.
- If a plan file already exists for the current task, load and display it.
- When planning ends, return to the previously active mode.

**Artifact format:**

A Markdown file with frontmatter:

```markdown
---
title: "Plan: <short description>"
created: 2026-08-12
updated: 2026-08-12
status: active
mode: balanced
---

## Goal

## Current state

## Open questions

## Tasks

- [ ] task one
- [ ] task two
```

### 4. `/config-override <key> <value>`

Set a transient or persisted configuration override.

**Behavior:**
- Parse a structured key-value pair.
- Apply it for the current session.
- Optionally persist it to project-local config (e.g. `.opencode/config.json` or
  `.opencode/overrides.json`).
- Reject overrides that conflict with project guardrails in `AGENTS.md`.

**Example:**

```text
/config-override pairing.mode = "ai-led"
```

### 5. Plan artifact storage convention

The harness should define a default location for plan artifacts and expose it
to skills.

- Default project path: `docs/plans/` if it exists, otherwise
  `.opencode/notes/`.
- Skills can read this path via a special variable or function.
- The harness should offer to create missing directories.

### 6. Mode context for skills

The harness should expose the current pairing mode to skills so they do not
have to re-read `.opencode/pairing-mode` themselves.

- Provide a context object or environment variable such as
  `OPENCODE_PAIRING_MODE`.
- Update it immediately when `/workflow mode` or `/config-override` runs.

### 7. Guardrails awareness

The harness should expose a project's `AGENTS.md` guardrails to skills in a
structured way.

- Parse confirmation gates, forbidden files, and required checks.
- Surface them to the model so the skill prompt does not have to duplicate
  them.
- Enforce forbidden-file rules at the tool-call level when possible.

## Open questions

- Should slash commands be implemented in the core harness, or should OpenCode
  expose an extension API that skills can use to register commands?
- Should `/plan` artifacts be tracked in git, or should they live in
  `.opencode/` and be gitignored?
- How should the harness handle a command that conflicts with a project
  guardrail?

## Related documents

- `docs/reference/development-workflow.md` — reference definition of the
  workflow (the skill was removed from OpenCode config on 2026-09-19).
- `docs/feedback/development-workflow.md` — feedback items that motivated these
  requirements.
