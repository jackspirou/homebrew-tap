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
| `claude-automode-proxy` | HTTPS proxy that patches GrowthBook feature flags |

## Auto Mode

### Why?

Claude Code gates auto mode in two ways:

1. **Server-side feature flags** — GrowthBook `remoteEval` returns `tengu_auto_mode_config.enabled = "disabled"` for some accounts. The HTTPS proxy intercepts these responses and patches the flag to `"enabled"`.
2. **Client-side plan check** — Since v2.1.139, the compiled binary hardcodes `if (isMaxPlan && model ∈ {opus-4-6, sonnet-4-6}) return false` in the `modelSupported` function, blocking auto mode for these models on Max plans regardless of feature flags. The `claude-auto` wrapper binary-patches this check on each launch.

### Supported models

| Model | Native Auto Mode | With This Patch |
|-------|------------------|-----------------|
| claude-opus-4-8 | Max, Team, Enterprise | (not needed) |
| claude-opus-4-7 | Max, Team, Enterprise | (not needed) |
| claude-opus-4-6 | Team, Enterprise only | **Max** |
| claude-sonnet-4-6 | Team, Enterprise only | **Max** |
| claude-haiku-4-6 | Not available | **Max** |
| claude-opus-4-5 | Not available | **Max** |
| claude-sonnet-4-5 | Not available | **Max** |
| claude-haiku-4-5 | Not available | **Max** |

The proxy unions Anthropic's server-returned `allowModels` with the floor above, so any model Anthropic ships server-side stays enabled — the table is a known floor, not a closed list.

### How it works

```
$ claude  (via alias)
     │
     ▼
┌─────────────────────────────────────────────────────┐
│  claude-auto wrapper:                               │
│                                                     │
│  1. Patch binary (Max plan gate → noop, idempotent) │
│  2. Start proxy if not running                      │
│  3. exec claude with HTTPS_PROXY pointed at proxy   │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  automode-proxy (HTTPS interception):               │
│  • Intercepts api.anthropic.com /api/eval/ responses│
│  • Patches tengu_auto_mode_config.enabled="enabled" │
│  • Patches ccr_auto_permission_mode=true            │
│  • Passes all other API traffic through unmodified  │
└─────────────────────────────────────────────────────┘
```

### Security

- **No macOS security settings are modified** — no keychain changes, no system trust store edits
- `NODE_TLS_REJECT_UNAUTHORIZED=0` is set only on the `claude` process, not system-wide
- Self-signed certs are stored locally in `~/.claude/automode-proxy/`
- The proxy binds to `127.0.0.1` only (not externally accessible)

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
1. Starts the auto mode proxy via `brew services`
2. Adds `alias claude='claude-auto'` to shell config
3. Sources brew wrapper for `brew upgrade claude-code` routing

## Usage

| Command | Mode | Notes |
|---------|------|-------|
| `claude` | Auto | Via alias, starts proxy if needed |
| `\claude` | Normal | Bypasses alias, runs claude directly |
| `claude-auto` | Auto | Direct wrapper call |

## Manual Control

```bash
brew services start claude-plus   # start proxy
brew services stop claude-plus    # stop proxy
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

## Limitations

- Requires Max, Team, or Enterprise subscription (auto mode uses a server-side classifier)
- The patch is local to your machine; doesn't affect team/org settings
