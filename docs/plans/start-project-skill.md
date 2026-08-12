---
title: "Start Project Skill Requirements"
type: plan
status: draft
created: 2026-08-12
updated: 2026-08-12
tags: [opencode, skill, project-template, onboarding]
---

# Start Project Skill Requirements

A new reusable skill for initializing a software project with OpenCode. The
skill is invoked when the user opens OpenCode in a fresh repository and asks
something like "start a new project" or "init this repo."

It should capture the repetitive setup work that currently happens ad hoc and
produce a project that the `development-workflow` skill can then drive.

## Trigger conditions

The skill should activate when the user:

- Opens OpenCode in a directory that lacks an `AGENTS.md`.
- Says phrases such as:
  - "start a new project"
  - "init this repo"
  - "set up this project"
  - "create an AGENTS.md for this project"

## Outputs

At minimum, the skill produces:

1. `AGENTS.md` — project-specific guardrails and conventions. Includes a
   "Setup" section if the user deferred a dedicated `README.md`.
2. `.opencode/pairing-mode` — default pairing mode (usually `balanced`).
3. Optional starter files depending on project type:
   - `flake.nix` or `shell.nix` for Nix projects.
   - `README.md` if the user wants human contributor docs now.
   - `docs/plans/` directory with an initial plan artifact.

## Workflow

### Step 1: Discover context

Before generating files, the skill asks or infers:

- Project name and one-line purpose.
- Programming language / framework / runtime.
- Whether to use Nix for the dev environment.
- Whether the project needs a long-running dev server.
- Default pairing mode preference.
- Whether to create a `README.md` now for human contributors, or add a "Setup"
  section to `AGENTS.md` that can migrate to `README.md` later.
- Where project documentation should live (`docs/`, `notes/`, etc.).

### Step 2: Select or scaffold project type

The skill supports common project types as templates:

| Type | What it scaffolds |
|------|-------------------|
| Nix flake | `flake.nix`, `.envrc`, `.gitignore` |
| Node / Vite | `package.json`, `flake.nix` with `nodejs_22`, basic src layout |
| Python | `pyproject.toml`, virtualenv setup, basic src layout |
| Plain | `AGENTS.md`, `.opencode/pairing-mode`, optional `README.md` |

New templates can be added over time. The first version can focus on Nix-based
and plain projects.

### Step 3: Generate `AGENTS.md`

Use a starter template with placeholders filled from the discovery step.
Required sections:

- **Project summary** — name, purpose, repo URL.
- **Deployment / apply process** — who triggers it, how, and any risks.
- **Required checks before done** — build, test, lint, format, etc.
- **Files not to touch in `ai-led` mode** — e.g. secrets, infra, CI.
- **Operations requiring confirmation** — deploy, data deletion, spending, etc.
- **Documentation conventions** — where ADRs, plans, and notes live.
- **Default pairing mode** — usually `balanced`.
- **Project-specific overrides** — anything that deviates from the general workflow.

### Step 4: Set default pairing mode

Write `.opencode/pairing-mode` with the chosen default. The `development-workflow`
skill will read this file at the start of each task.

### Step 5: Offer a plan artifact

For non-trivial setups, offer to write a short plan file to `docs/plans/` or
`.opencode/notes/` describing the initial tasks and pairing mode.

### Step 6: Verify and hand off

Run any available checks:

- `nix flake check` or `nix develop --command true` for Nix projects.
- `git status` to confirm generated files are present.

Then summarize what was created and tell the user they can now start
development work.

## Integration with other skills

- **development-workflow** — reads `.opencode/pairing-mode` and `AGENTS.md`;
  relies on this skill to create them.
- **tmux-aware** — if the project needs a dev server, the start-project skill
  should mention tmux conventions and perhaps create a tmux session or window.
- **nix-flake** — for Nix projects, this skill should generate or validate the
  flake.

## Open questions

- Should the skill live in this system repo under `home/skills/start-project/`,
  or should it be a separate repository?
- Should templates be Nix expressions, plain files, or a mix?
- How does the skill detect the desired project type? Ask explicitly, infer
  from existing files, or both?
- Should the generated `AGENTS.md` include a starter `justfile` recipe section?

## Related documents

- `home/skills/development-workflow/PROMPT.md`
- `docs/reference/development-workflow.md`
- `docs/feedback/development-workflow.md` — items #4 and #8 motivated this
  skill.
- `docs/plans/opencode-harness-requirements.md` — harness features that would
  improve this skill (slash commands, plan artifacts).
