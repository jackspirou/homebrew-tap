# Claude Auto Mode

Enables [auto mode](https://www.anthropic.com/engineering/claude-code-auto-mode) for Claude Code with Opus 4.6 or Sonnet 4.6 on Max plan.

## Why this formula?

On Max plan, auto mode officially requires Opus 4.7. This formula patches the GrowthBook feature flag to enable auto mode with older models that technically support it but are artificially restricted.

### Supported models

| Model | Native Auto Mode | With This Patch |
|-------|------------------|-----------------|
| claude-opus-4-7 | Max, Team, Enterprise | (not needed) |
| claude-opus-4-6 | Team, Enterprise only | Max |
| claude-sonnet-4-6 | Team, Enterprise only | Max |

## How it works

1. Claude Code stores GrowthBook feature flags in `~/.claude.json`
2. The flag `tengu_auto_mode_config.enabled` controls auto mode availability
3. GrowthBook refreshes this flag every 6 hours (or on auth change)
4. This daemon watches the config file and re-patches instantly when it changes

## Install

```bash
brew tap jackspirou/tap
brew install --HEAD jackspirou/tap/claude-automode
brew services start claude-automode
```

Dependencies (`fswatch`, `jq`) are installed automatically.

## Usage

### Background service (recommended)

```bash
# Start (also starts on login)
brew services start claude-automode

# Stop
brew services stop claude-automode

# Restart
brew services restart claude-automode

# Check status
brew services list | grep claude-automode
```

### Wrapper command

Patches once and runs claude with auto mode:

```bash
claude-auto [claude args...]
```

Add to `~/.zshrc` to make it the default:

```bash
alias claude='claude-auto'
```

### Manual daemon

```bash
# Run in background
claude-automode-daemon &

# Patch once and exit
claude-automode-daemon --once
```

## Logs

```bash
cat /opt/homebrew/var/log/claude-automode.log
```

## Uninstall

```bash
brew services stop claude-automode
brew uninstall claude-automode
```

## How the patch works

The daemon modifies this JSON path in `~/.claude.json`:

```json
{
  "cachedGrowthBookFeatures": {
    "tengu_auto_mode_config": {
      "enabled": "enabled"  // patched from "disabled"
    }
  }
}
```

When Claude Code starts, it reads this cached value. The daemon ensures it stays patched even after GrowthBook refreshes.

## Limitations

- Only works for models that pass Claude Code's `modelSupportsAutoMode()` check (Opus 4.6+, Sonnet 4.6+)
- Requires Max, Team, or Enterprise subscription (auto mode uses a server-side classifier)
- The patch is local to your machine; doesn't affect team/org settings
