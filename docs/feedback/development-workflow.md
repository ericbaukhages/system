---
title: "Development Workflow Feedback"
type: feedback
status: open
created: 2026-08-11
updated: 2026-08-12
tags: [ai, workflow, collaboration, feedback]
---

# Development Workflow Feedback

Feedback captured after prototyping the `development-workflow` skill on the
Move Tracker greenfield project (2026-08-11). Each item follows the same
structure so we can track status as we apply changes.

## Index

| # | Item | Priority | Status |
|---|------|----------|--------|
| 1 | [Mode switching is too manual](#1-mode-switching-is-too-manual) | medium | requirements-drafted |
| 2 | [`ai-led` collides with hard guardrails](#2-ai-led-collides-with-hard-guardrails) | high | applied |
| 3 | [`human-led` boundaries are fuzzy](#3-human-led-boundaries-are-fuzzy) | high | applied |
| 4 | [Onboarding checklist needs a template](#4-onboarding-checklist-needs-a-template) | medium | skill-planned |
| 5 | [Tooling-specific skills are siloed](#5-tooling-specific-skills-are-siloed) | low | pending |
| 6 | ["Natural checkpoints" in `ai-led` are undefined](#6-natural-checkpoints-in-ai-led-are-undefined) | medium | applied |
| 7 | [Planning lacks an artifact](#7-planning-lacks-an-artifact) | low | pending |
| 8 | [Documentation tension: README vs. AGENTS.md](#8-documentation-tension-readme-vs-agentsmd) | medium | pending |
| 9 | [Required checks are project-specific, not workflow-wide](#9-required-checks-are-project-specific-not-workflow-wide) | medium | applied |

## 1. Mode switching is too manual

- **Observation:** Switching modes requires the human to say a specific phrase,
  then the AI updates `.opencode/pairing-mode`. This is fine for deliberate
  switches but feels ceremonial for short tasks.
- **Impact:** Friction during quick context switches; ambiguity about whether
  the mode actually changed.
- **Proposed change:** Add harness support for slash commands such as
  `/config-override pairing.mode = ...` to remove ambiguity. Until then, the AI
  should confirm the switch explicitly and state what behavior changes.
- **Status:** requirements-drafted
- **Note:** Requirements captured in
  `docs/plans/opencode-harness-requirements.md`. Implementation is blocked on
  harness/plugin support.

## 2. `ai-led` collides with hard guardrails

- **Observation:** `ai-led` says the AI implements independently, but project
  guardrails (e.g. "do not commit without explicit approval") still require
  human checkpoints. That is the right priority, but the workflow does not make
  it explicit.
- **Impact:** The human expects speed and the AI keeps asking for approval,
  which feels like a broken mode.
- **Proposed change:** Add a "guardrails override" statement at the top of each
  mode description, and list common gates (commit, deploy, data deletion,
  tech-stack change) that always require confirmation regardless of mode.
- **Status:** applied

## 3. `human-led` boundaries are fuzzy

- **Observation:** In the Move Tracker test, the human wrote the search filter
  and the AI reviewed. At the very end the AI made a tiny polish edit
  (`type="text"`) and committed. That was efficient, but it blurred the line
  of who was driving.
- **Impact:** Role confusion in `human-led` mode; the AI may inadvertently take
  over.
- **Proposed change:** In `human-led`, the AI should not touch code unless the
  human explicitly asks for the implementation. Review comments should be hints,
  not patches. If the AI does make an edit, it should call it out explicitly.
- **Status:** applied

## 4. Onboarding checklist needs a template

- **Observation:** Creating `AGENTS.md` from scratch forced a lot of
  back-and-forth. The workflow lists questions to answer but does not provide
  a starter document.
- **Impact:** New projects spend extra turns agreeing on the same basic
  guardrails structure.
- **Proposed change:** Ship a starter `AGENTS.md` template (or a `just`
  scaffold) with placeholders for deployment process, required checks,
  unilateral-edit restrictions, and confirmation gates.
- **Status:** skill-planned
- **Note:** Requirements for a new `start-project` skill are captured in
  `docs/plans/start-project-skill.md`. The skill will generate a starter
  `AGENTS.md` as part of project initialization.

## 5. Tooling-specific skills are siloed

- **Observation:** The `development-workflow` skill does not know about the
  `tmux-aware` skill or Nix conventions. During the test, dev-server management
  and `nix develop` invocation were handled by separate skills.
- **Impact:** A greenfield project needs the workflow skill to pull in the
  right context automatically.
- **Proposed change:** The workflow skill should reference or load
  environment/runtime skills when relevant (e.g. tmux for long-running servers,
  Nix for dev shells). At minimum, the onboarding checklist should ask whether
  the project uses Nix/tmux/CI and adapt the required checks accordingly.
- **Status:** pending

## 6. "Natural checkpoints" in `ai-led` are undefined

- **Observation:** The workflow says the human reviews at "natural checkpoints"
  but does not define what those are. In the test, the checkpoint was "feature
  is done and builds." For larger features this could be per-file,
  per-component, or per-commit.
- **Impact:** Inconsistent review granularity; the AI may lump too much work
  together or interrupt too often.
- **Proposed change:** Give the AI heuristics for checkpoints, such as:
  - after each self-contained feature or bug fix,
  - before touching guarded files,
  - before any commit or deployment,
  - when a build/lint/test step fails.
- **Status:** applied

## 7. Planning lacks an artifact

- **Observation:** `/plan` is mentioned but not implemented by the harness. The
  conversational planning worked for a small project, but complex work would
  benefit from a written plan.
- **Impact:** Plans live only in chat history and are hard to reference during
  implementation.
- **Proposed change:** When `/plan` is invoked (or planning is otherwise
  needed), the AI should offer to write a short plan file and reference it
  during implementation. Suggested locations: `.opencode/notes/` or
  `docs/plans/`.
- **Status:** pending

## 8. Documentation tension: README vs. AGENTS.md

- **Observation:** Global instructions tell the AI not to create README files
  proactively, while project guardrails say README should be for human
  contributors. This left Move Tracker with a good `AGENTS.md` but no README.
  Human contributors will need setup instructions somewhere.
- **Impact:** New projects may end up with contributor setup docs missing or
  inconsistently placed.
- **Proposed change:** During onboarding, the AI should explicitly ask whether
  to create a README, or add a "Setup" section to `AGENTS.md` that can later be
  migrated to README.
- **Status:** pending

## 9. Required checks are project-specific, not workflow-wide

- **Observation:** The workflow says "update project memory" but does not
  enforce a standard pre-done checklist. Each project's `AGENTS.md` defines its
  own, which is flexible but inconsistent.
- **Impact:** Easy to forget universal basics (staged files, no secrets,
  passing build) when each project invents its own list.
- **Proposed change:** Add a small universal checklist to the workflow skill
  (build passes, dev server healthy, new files staged, no secrets committed)
  that always applies, plus a project-specific extension in `AGENTS.md`.
- **Status:** applied

## Source

- Prototype test: Move Tracker (Vite + React), repository `~/Projects/move`,
  2026-08-11.
- Original location before reorganization:
  `docs/reference/development-workflow.md` under
  "Critical feedback / proposed workflow improvements."
