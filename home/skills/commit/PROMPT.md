# Committing changes

When the user asks to make a commit, follow these steps in order. Do not run `git commit` until the user has confirmed the staged changes and the proposed message.

## 1. Inspect the working tree

Run `git status` and read the output. Summarize for the user:

- Which files are modified, added, or deleted.
- Which files are already staged versus unstaged.
- Whether there are untracked files that look relevant.

## 2. Review the diff

Run `git diff` (and `git diff --staged` if anything is already staged). Look for:

- Changes that match what the user intended to commit.
- Accidental changes, debugging leftovers, or secrets.
- New files that have not yet been added.

Point out anything surprising or unrelated to the user before proceeding.

## 3. Decide what to stage

Ask the user whether to:

- Stage all changes (`git add -A`).
- Stage specific files or hunks only.
- Leave certain files unstaged.

If the user has not specified, propose a staging plan based on the diff and wait for confirmation.

## 4. Propose a commit message

Draft a concise commit message that matches the repository's style. Good practices:

- Use the imperative mood in the subject line (e.g., "Add", "Fix", "Refactor", "Update").
- Keep the subject line under 50 characters when practical.
- Add a blank line and a body when the change needs explanation.
- Reference relevant issues or PRs if the project uses them.
- Do not end the subject with a period.

Show the proposed message to the user and ask for approval or edits.

## 5. Include model attribution

When you execute `git commit` on the user's behalf, the commit must disclose that it was assisted by a model. Name the current model in the attribution line. Add it in the commit body, after the explanatory text and before any trailers such as `Signed-off-by`.

Preferred form:

```
Assisted-by: opencode-go/kimi-k2.7-code
```

or, if the repository already records co-authors this way:

```
Co-authored-by: opencode-go/kimi-k2.7-code
```

If the repository defines its own model-attribution format (for example in `AGENTS.md`, `CONTRIBUTING.md`, or a commit-message template), use that format instead.

If the user explicitly asks you to skip model attribution for a specific commit, honor that request for that commit only and note the exception in your response.

## 6. Commit only after confirmation

Once the user confirms the staged files and the message, run:

```bash
git commit -m "subject line" -m "optional body" -m "Assisted-by: opencode-go/kimi-k2.7-code"
```

If the repository uses commit hooks (e.g., pre-commit), let them run normally.

## 7. Push only when explicitly asked

Do not push after committing unless the user explicitly requests it. If asked, prefer the current branch's upstream:

```bash
git push
```

## Guardrails

- Never commit secrets, credentials, or large generated artifacts.
- Never amend, reset, rebase, force-push, or otherwise rewrite history unless explicitly asked.
- If the user is in the middle of a complex operation (merge, rebase, cherry-pick), ask how to proceed rather than guessing.
- Respect `.gitignore` and do not add ignored files without explicit instruction.
