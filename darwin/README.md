# nix-darwin work MacBook

Opinionated nix-darwin configuration for an Apple Silicon MacBook used for work.

## Apply

```bash
darwin-rebuild switch --flake .#eric-macbook
```

## Status

This is a skeleton. The base module enables flakes and zsh; work-specific
settings (1Password, Hammerspoon, Ollama, etc.) should be added to
`modules/darwin/work.nix` as needed.

## Local recipe

```bash
just darwin
```
