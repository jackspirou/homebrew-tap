# Claude Plus

Auto mode, channel switching, and setup tools for [Claude Code](https://www.anthropic.com/claude-code).

## Quick Start

```bash
brew install jackspirou/tap/claude-code
brew install --HEAD jackspirou/tap/claude-plus
claude-setup && source ~/.zshrc
```

Use `claude` for auto mode, `\claude` for normal mode.

## What's included

| Command | Purpose |
|---------|---------|
| `claude-setup` | One-time configuration (idempotent, reversible) |
| `claude-auto` | Wrapper that runs claude with auto mode |
| `claude-channel` | Switch between latest/stable channels, pin versions |

## Auto Mode

`claude-auto` adds `--permission-mode auto` for you. The alias that
`claude-setup` writes points `claude` at this wrapper, so auto mode is the
default for an interactive session.

Remote Control does not inherit a flag placed before the verb. For
`claude rc` and `claude remote-control`, the wrapper puts
`--permission-mode auto` after the verb. An explicit `--permission-mode`
from the caller is left alone.

Auto mode is a server-gated feature. Anthropic controls availability per
account and per model.

## Channel Switching

Switch between Claude Code release channels:

```bash
claude-channel                   # show status + available updates
claude-channel list              # list recent releases with dates
claude-channel latest            # switch to latest (bleeding edge)
claude-channel stable            # switch to stable
claude-channel pin 2.1.105       # freeze to specific version
claude-channel upgrade           # update to newest of current channel
claude-channel inspect 2.1.114   # show changelog for a version
```

See [claude-code docs](claude-code.md) for full channel documentation.

## Setup Command

```bash
claude-setup          # configure everything (idempotent)
claude-setup status   # check current state
claude-setup undo     # revert all changes
```

What `claude-setup` does:

1. Adds `alias claude='claude-auto'` to shell config.
2. Sources brew wrapper for `brew upgrade claude-code` routing.

## Usage

| Command | Mode | Notes |
|---------|------|-------|
| `claude` | Auto | Via alias |
| `\claude` | Normal | Bypasses alias, runs claude directly |
| `claude-auto` | Auto | Direct wrapper call |

## Uninstall

```bash
claude-setup undo
brew uninstall claude-plus
```
