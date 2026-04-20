# Claude Auto Mode

Enables [auto mode](https://www.anthropic.com/engineering/claude-code-auto-mode) for Claude Code with 4.5 and 4.6 model families on Max plan.

## Quick Start

```bash
brew install --HEAD jackspirou/tap/claude-automode
echo "alias claude='claude-auto'" >> ~/.zshrc
source ~/.zshrc
```

Done. Now just use `claude` normally with auto mode enabled.

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

1. Claude Code stores GrowthBook feature flags in `~/.claude.json`
2. The flag `tengu_auto_mode_config.enabled` controls auto mode availability
3. The `claude-auto` wrapper patches the config before each invocation
4. Auto mode just works - no background service needed

## Usage

### Alias (recommended)

Add to your shell config:

```bash
# ~/.zshrc or ~/.bashrc
alias claude='claude-auto'
```

Then use `claude` normally - the wrapper patches and runs with `--permission-mode auto`.

### Background service (optional)

If you use plain `claude` (without the alias) and want persistent patching even when GrowthBook refreshes every 6 hours:

```bash
brew services start claude-automode
```

Service commands:

```bash
brew services stop claude-automode
brew services restart claude-automode
brew services list | grep claude-automode
```

### Manual

```bash
# Patch once and exit
claude-automode-daemon --once

# Run daemon in foreground
claude-automode-daemon
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
