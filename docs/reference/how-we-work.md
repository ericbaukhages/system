---
title: "How We Work"
type: reference
status: draft
created: 2026-09-25
updated: 2026-09-25
tags: [conventions, workflow, collaboration, code-review]
---

# How We Work

This document captures the conventions and expectations we try to follow in this repository. It is intentionally lightweight and should be updated when our practices change.

## Decisions

- Record significant decisions in docs (plans, reference notes, ADRs) rather than relying on chat history.
- Prefer small, reviewable changes over large sweeping refactors.
- When in doubt, propose the approach before implementing it.

## Code

- Follow the existing style and patterns in the file or module you are changing.
- Keep functions and modules focused; avoid unrelated changes in the same commit.
- Add tests for new behavior and regression tests for bug fixes.
- Do not commit secrets, credentials, tokens, or personal data.
- Run the project's checks before considering work done (`just check`, `just fmt`, etc.).

## Reviews

- Reviews focus on correctness, security, privacy, maintainability, and fit with project conventions.
- Reviewers should cite specific files and lines and explain why something matters.
- Authors should treat review feedback as a conversation, not a checklist to rush through.
- Security and privacy issues block merging until resolved.

## Documentation

- Keep `AGENTS.md` up to date with project-specific guidance for AI assistants.
- Keep `README.md` focused on human contributors.
- Add or update docs when a change reveals a new decision or contradicts existing guidance.

## AI-assisted work

- AI assistance is fine for implementation, exploration, and reviews.
- The human remains responsible for the final change.
- AI-assisted commits must disclose the model used (see `AGENTS.md`).
- Do not let the AI commit, push, deploy, or rewrite history without explicit human confirmation.

## Security and privacy

- Never log or expose secrets, tokens, IP addresses, or personally identifiable information.
- Prefer least-privilege access and secure defaults.
- Question any change that increases data collection, retention, or external sharing.

## Source

- Team convention, recorded here for reference and for the `code-review` skill.
