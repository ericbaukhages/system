# Tmux-aware session context

The user runs every opencode session wrapped in tmux. Treat the current tmux session as the runtime environment for commands and long-running processes.

## User's tmux configuration

Tmux is configured via home-manager in `home/shell.nix`. Key facts:

- Prefix key is the default `C-b` (not rebound).
- Mouse support is enabled.
- `default-terminal` is set to `screen-256color`.
- The zsh alias `a = "tmux attach"` exists, but opencode should use explicit `tmux` commands.

For any tmux-specific behavior questions, check `home/shell.nix` first.

## Conventions

- Prefer tmux windows/panes over agent subprocesses for long-running work.
- Name windows after the service or task (e.g. `:api`, `:web`, `:nix-build`).

## Focus

When opening a new tmux window, pane, or tab for the user, do not steal focus unless they explicitly ask you to. Creating a window with `tmux new-window` automatically switches to it; use the detached form `tmux new-window -d ...` (or `tmux split-window -d ...`) so the user stays where they are.

Only switch the user's focus (e.g. `tmux select-window -t :<name>` or starting a process without `-d`) when they explicitly request it, such as "find the appropriate file and open it in my vim environment."

## Long-running processes and dev servers

When asked to start a local dev server, background service, or any process expected to outlive the current turn:

1. Check whether a tmux session is active (`test -n "$TMUX"` or `tmux display-message -p '#S'`).
2. Before creating a window, check for an existing one with the same name (`tmux list-windows -F '#W'`).
3. If it does not exist, create a new window without stealing focus:
   - `tmux new-window -d -n <name> -c <project-dir> '<command>'`
4. If it exists, either reuse it or ask the user before replacing it.
5. Capture recent output with `tmux capture-pane -t :<name> -p` when reporting status.
6. Stop a running server gracefully with `tmux send-keys -t :<name> C-c`.

## Short commands

One-off, short-lived commands can still be run through the normal `bash` tool. Use tmux windows only when the process is long-running or when the user explicitly wants it detached from the agent.

## Avoid

- Do not start dev servers as agent subprocesses unless the user explicitly asks.
- Do not kill tmux windows with `kill` or `pkill` when a graceful `C-c` is possible.
