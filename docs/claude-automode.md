# Claude Auto Mode

Enables [auto mode](https://www.anthropic.com/engineering/claude-code-auto-mode) for Claude Code with 4.5 and 4.6 model families on Max plan.

## Quick Start

```bash
brew install --HEAD jackspirou/tap/claude-automode
echo "alias claude='claude-auto'" >> ~/.zshrc
source ~/.zshrc
```

Done. Use `claude` for auto mode, `\claude` for normal mode.

## Why this formula?

On Max plan, auto mode officially requires Opus 4.7. This formula patches the GrowthBook feature flags to enable auto mode with older models that are artificially restricted.

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

## How it works

```
┌─────────────────────────────────────────────────────────────┐
│  $ claude  (via alias)                                      │
│       │                                                     │
│       ▼                                                     │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  claude-auto wrapper:                               │    │
│  │                                                     │    │
│  │  if watcher not running:                            │    │
│  │    1. Patch config (sync)    ← guarantees ready     │    │
│  │    2. Start watcher (async)  ← for future refreshes │    │
│  │                                                     │    │
│  │  3. exec claude --permission-mode auto              │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  BACKGROUND WATCHER (started automatically)                 │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  claude-automode-daemon                                │ │
│  │  • Re-patches when GrowthBook refreshes (every 6 hrs)  │ │
│  │  • Keeps config patched for IDE/direct invocations     │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Usage

| Command | Mode | Notes |
|---------|------|-------|
| `claude` | Auto | Via alias, starts watcher if needed |
| `\claude` | Normal | Bypasses alias |
| `claude-auto` | Auto | Direct wrapper call |

### Manual service control

```bash
brew services start claude-automode   # start watcher
brew services stop claude-automode    # stop watcher
brew services list | grep claude      # check status
```

## Logs

```bash
cat /opt/homebrew/var/log/claude-automode.log
```

## Uninstall

```bash
brew services stop claude-automode  # if running
brew uninstall claude-automode
# Remove alias from ~/.zshrc if added
```

## How the patch works

The formula patches `~/.claude.json`:

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
