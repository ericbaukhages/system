# Code review

When the user asks for a code review, determine the scope first, then inspect the change systematically and give specific, actionable feedback.

## 1. Clarify the scope

Ask or infer what is being reviewed. The user may request:

- A pull request (provide number or URL).
- A branch against `main` (or another base branch).
- A specific commit or commit range.
- A diff, patch, or set of files.
- Some other directive (e.g., "review my changes since yesterday").

If the scope is ambiguous, state your assumptions and confirm them before diving in.

## 2. Gather context

Before reading the diff, understand:

- What the change is trying to accomplish.
- The project's conventions (read `AGENTS.md`, `README.md`, and `docs/reference/how-we-work.md` if they exist).
- Any related issues, PR descriptions, or commit messages.
- The test/build/lint commands the project uses.

If the project has a `justfile`, `Makefile`, or package scripts, note the relevant verification commands.

## 3. Inspect the change

Fetch or generate the diff using the appropriate tool:

- PR: `gh pr view <number>` and `gh pr diff <number>`.
- Branch against base: `git diff <base>..<branch>`.
- Commit or range: `git show <commit>` or `git diff <commit-range>`.
- Working tree: `git diff` / `git diff --staged`.

Read the diff carefully. For non-trivial changes, also read the surrounding code to understand context, not just the changed lines.

## 4. Review categories

For each finding, be specific: cite the file, line number(s), and explain *why* it matters. Suggest a concrete fix or ask a clarifying question when the intent is unclear.

### Correctness

- Logic errors, off-by-one issues, null/undefined handling, race conditions.
- Incorrect assumptions about input data or state.
- API misuse or mismatched types.
- Error handling that swallows exceptions or returns misleading results.

### Tests

- New behavior should have tests. Bug fixes should have a regression test.
- Tests should cover edge cases, failure modes, and boundary conditions.
- Existing tests should still pass; check for flakes or broken assertions.
- Mocking should not hide real bugs.

### Security

- Injection vulnerabilities (SQL, command, XSS, template injection).
- Unsafe deserialization or parsing of untrusted input.
- Missing authentication, authorization, or access control.
- Secrets, credentials, or tokens in code, logs, or tests.
- Insecure defaults or misconfigured permissions.
- Dependency versions with known vulnerabilities.

### Privacy

- Logging or telemetry that captures PII, tokens, IP addresses, or sensitive user data.
- Data retention or sharing that exceeds what the feature needs.
- Missing anonymization or aggregation where appropriate.
- API responses that leak internal identifiers or user details.

### Performance and scalability

- Unnecessary work in hot paths (N+1 queries, repeated allocations).
- Inefficient algorithms or data structures.
- Blocking operations in async contexts.
- Memory leaks or unbounded caches.

### Maintainability and readability

- Clear naming, consistent style, and appropriate abstraction.
- Functions that are too long, do too many things, or have surprising side effects.
- Duplicated logic that could be shared.
- Comments that explain *why*, not *what*.
- Dead code, unused imports, or leftover debugging artifacts.

### Conventions and project fit

- Follow the project's existing patterns (read `AGENTS.md` and `docs/reference/how-we-work.md`).
- Match the language/framework idioms used in the repo.
- Respect project-specific guardrails (files not to touch, required checks, etc.).

## 5. Summarize

End the review with a short summary:

- Overall verdict: approve, approve with minor changes, request changes, or needs discussion.
- The most important issues (security/privacy/correctness first).
- Suggested next steps for the author.

Keep the tone constructive and specific. Avoid generic praise or nit-picking without context.

## 6. Follow-up

If the user wants to address the feedback, offer to help implement fixes or re-review after changes. Do not commit or push anything unless explicitly asked.
