# Claude Code

A Homebrew cask for [Claude Code](https://www.anthropic.com/claude-code) that tracks the **latest** release channel by default and lets you switch channels or pin to any specific version.

## Why this tap?

The official Homebrew cask tracks the **stable** channel, which can lag behind GitHub releases by days or weeks. This tap gives you control over which version you run.

| Channel | What it tracks |
|---------|---------------|
| `latest` | Bleeding edge — same as [GitHub releases](https://github.com/anthropics/claude-code/releases) |
| `stable` | Anthropic's promoted stable releases (lags behind latest) |

## Install

```bash
brew tap jackspirou/tap
brew install jackspirou/tap/claude-code
```

This installs the `claude` binary.

## Shell wrapper

To make `brew upgrade claude-code` resolve to this tap, install [claude-plus](claude-plus.md):

```bash
brew install --HEAD jackspirou/tap/claude-plus
claude-setup
```

This also enables auto mode, channel switching, and the brew routing wrapper.

## Channel switching

The `claude-channel` command is installed by the `claude-plus` formula.

### Commands

```bash
# Show current version and what's available
claude-channel status
```

```
Installed binary:        2.1.111
Cask version:            2.1.111
Livecheck tracks:        latest

Channel versions:
  latest:  2.1.111
  stable:  2.1.97

You are on the latest version.
```

```bash
# Switch to the latest channel (bleeding edge)
claude-channel latest

# Switch to the stable channel
claude-channel stable

# Pin to a specific version
claude-channel version 2.1.105

# Change what `brew upgrade` tracks without reinstalling
claude-channel livecheck stable

# Push current cask state to GitHub
claude-channel sync
```

### Switching channels

Each channel command resolves the current version, updates the cask, and reinstalls in one step:

```bash
$ claude-channel latest
Latest channel resolves to: 2.1.111
Cask version set to 2.1.111
Livecheck now tracks: latest

Reinstalling...
🍺  claude-code was successfully installed!
```

### Pinning a version

Pin to any version published to Anthropic's CDN:

```bash
$ claude-channel version 2.1.100
Cask version set to 2.1.100

Reinstalling...
🍺  claude-code was successfully installed!
```

Pinning does not change the livecheck channel, so `brew upgrade` will still move you forward based on your tracked channel. To freeze completely, pin the version and set livecheck to match:

```bash
claude-channel version 2.1.100
claude-channel livecheck stable
```

## Upgrading

Once installed, upgrade like any other cask:

```bash
brew upgrade claude-code
```

This checks the livecheck URL for your tracked channel (latest or stable) and upgrades if a newer version is available.

## Auto mode (4.5/4.6 on Max plan)

Auto mode officially requires Opus 4.7 on Max plan. To enable it with 4.5/4.6 models, install `claude-plus` (see above) which handles auto mode, channel switching, and shell configuration in one step.

See [claude-plus docs](claude-plus.md) for details.

## Uninstall

```bash
brew uninstall claude-code
brew untap jackspirou/tap
```

If you have `claude-plus` installed, also run `claude-setup undo`.
