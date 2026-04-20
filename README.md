# Homebrew Tap

Personal [Homebrew](https://brew.sh) tap by [@jackspirou](https://github.com/jackspirou).

## Quick Start (Claude Code)

```bash
brew install jackspirou/tap/claude-code
brew install --HEAD jackspirou/tap/claude-plus
claude-setup && source ~/.zshrc
```

After setup:

| Command | What it does |
|---------|-------------|
| `claude` | Claude Code with auto mode enabled |
| `\claude` | Claude Code without auto mode |
| `claude-channel` | Switch between latest/stable, pin versions |
| `claude-setup status` | Check current configuration |
| `claude-setup undo` | Revert all changes |

## Why two packages?

Homebrew requires a [Cask](https://docs.brew.sh/Cask-Cookbook) to download pre-built binaries and a [Formula](https://docs.brew.sh/Formula-Cookbook) to generate scripts and run services. These can't be combined into one package.

| Package | Type | What it does |
|---------|------|-------------|
| [claude-code](Casks/claude-code.rb) | Cask | Downloads the `claude` binary from Anthropic's CDN |
| [claude-plus](Formula/claude-plus.rb) | Formula | Auto mode, channel switching, shell setup, background watcher |

`claude-setup` wires them together so they feel like one install.

## Docs

- [claude-code](docs/claude-code.md) — binary installation, channel switching, version pinning
- [claude-plus](docs/claude-plus.md) — auto mode, setup command, architecture details

## Other Casks

| Cask | Description |
|------|-------------|
| [scout](Casks/scout.rb) | Native macOS file manager built with Swift and AppKit |
