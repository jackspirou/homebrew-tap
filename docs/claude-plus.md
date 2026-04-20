# Claude Plus

Auto mode, channel switching, and setup tools for [Claude Code](https://www.anthropic.com/claude-code).

## Quick Start

```bash
brew install jackspirou/tap/claude-code
brew install --HEAD jackspirou/tap/claude-plus
claude-setup && source ~/.zshrc
```

That's it. Use `claude` for auto mode, `\claude` for normal mode.

## What's included

| Command | Purpose |
|---------|---------|
| `claude-setup` | One-time configuration (idempotent, reversible) |
| `claude-auto` | Wrapper that runs claude with auto mode |
| `claude-channel` | Switch between latest/stable channels, pin versions |
| `claude-automode-daemon` | Background watcher that keeps auto mode patched |

## Auto Mode

### Why?

On Max plan, auto mode officially requires Opus 4.7. This formula patches the GrowthBook feature flags to enable it with older models.

### Supported models

| Model | Native Auto Mode | With This Patch |
|-------|------------------|-----------------|
| claude-opus-4-7 | Max, Team, Enterprise | (not needed) |
| claude-opus-4-6 | Team, Enterprise only | **Max** |
| claude-sonnet-4-6 | Team, Enterprise only | **Max** |
| claude-haiku-4-6 | Not available | **Max** |
| claude-opus-4-5 | Not available | **Max** |
| claude-sonnet-4-5 | Not available | **Max** |
| claude-haiku-4-5 | Not available | **Max** |

### How it works

```
$ claude  (via alias)
     │
     ▼
┌─────────────────────────────────────────────────────┐
│  claude-auto wrapper:                               │
│                                                     │
│  if watcher not running:                            │
│    1. Patch config (sync)    ← guarantees ready     │
│    2. Start watcher (async)  ← for future refreshes │
│                                                     │
│  3. exec claude --permission-mode auto              │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  Background watcher (started automatically)         │
│  • Re-patches when GrowthBook refreshes (6 hrs)    │
│  • Keeps config patched for IDE/direct invocations  │
└─────────────────────────────────────────────────────┘
```

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
1. Patches `~/.claude.json` for auto mode
2. Starts the background watcher service
3. Adds `alias claude='claude-auto'` to shell config
4. Sources brew wrapper for `brew upgrade claude-code` routing

## Usage

| Command | Mode | Notes |
|---------|------|-------|
| `claude` | Auto | Via alias, starts watcher if needed |
| `\claude` | Normal | Bypasses alias, runs claude directly |
| `claude-auto` | Auto | Direct wrapper call |

## Manual Control

```bash
brew services start claude-plus   # start watcher
brew services stop claude-plus    # stop watcher
brew services list | grep claude  # check status
```

## Logs

```bash
cat /opt/homebrew/var/log/claude-plus.log
```

## Uninstall

```bash
claude-setup undo
brew uninstall claude-plus
```

## How the patch works

Modifies `~/.claude.json`:

```json
{
  "cachedGrowthBookFeatures": {
    "tengu_auto_mode_config": {
      "enabled": "enabled",
      "allowModels": ["claude-opus-4-5", "claude-sonnet-4-5", "claude-haiku-4-5",
                      "claude-opus-4-6", "claude-sonnet-4-6", "claude-haiku-4-6"]
    }
  }
}
```

- `enabled` unlocks auto mode for supported model families
- `allowModels` bypasses the hardcoded model check for 4.5/4.6 families

## Limitations

- Requires Max, Team, or Enterprise subscription (auto mode uses a server-side classifier)
- The patch is local to your machine; doesn't affect team/org settings
