# Agent prompts

Harness-agnostic skill and agent prompts.

Each skill or agent is a directory containing:

- `PROMPT.md` — the prompt text.
- `default.nix` — metadata (`name`, `description`, and optional `mode` for agents).

## Layout

```
agents/
├── skills/
│   └── <name>/
│       ├── PROMPT.md
│       └── default.nix
└── agents/
    └── <name>/
        ├── PROMPT.md
        └── default.nix
```

## Adapters

The system config consumes these prompts through a harness-specific adapter:

- `home/opencode.nix` — emits OpenCode config files under `~/.config/opencode/`.

To switch to a different harness, add a new adapter under `home/` that reads the
same `agents/` prompts and emits that harness's configuration format.

## Adding a skill

1. Create `agents/skills/<name>/`.
2. Add `PROMPT.md` with the prompt content.
3. Add `default.nix` with at least `{ name = "..."; description = "..."; }`.
4. Run `just check` to verify the OpenCode adapter still evaluates.
