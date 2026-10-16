# home-manager dotfiles

Shared dotfiles for Linux and macOS.

## Apply

**Linux:**

```bash
nix run home-manager -- switch --flake .#eric
```

**macOS:**

```bash
nix run home-manager -- switch --flake .#eric-darwin
```

## What's included

- zsh with fzf, zoxide, starship, tmux
- Neovim with LSP support for Nix, TypeScript, and web languages
- Kitty terminal
- Git and SSH config
- Minimal OpenCode global config
- Optional trial tools (`home/trials/`)

## Node.js

Node is managed with [fnm](https://github.com/Schniz/fnm). Set a default:

```bash
fnm install 22
fnm default 22
```

Per-project Node versions can be pinned with `.nvmrc` or `.node-version`.

## Trial tools

Enable experimental tools by setting:

```nix
myHome.trials.enable = true;
```

in your home configuration. Tools in `trials/` are not installed by default.

## Local recipes

```bash
just home         # Linux
just home-darwin  # macOS
```
