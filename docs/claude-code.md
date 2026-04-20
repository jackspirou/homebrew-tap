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
brew install jackspirou/tap/claude-code
```

This installs the `claude` binary.

## Claude Plus (recommended)

For auto mode, channel switching, and shell setup in one step:

```bash
brew install --HEAD jackspirou/tap/claude-plus
claude-setup
```

This configures:
- Auto mode for 4.5/4.6 models on Max plan
- `claude-channel` command for version management
- Brew routing so `brew upgrade claude-code` uses this tap
- Shell alias (`claude` runs with auto mode, `\claude` for normal)

See [claude-plus docs](claude-plus.md) for details.

## Channel Switching

The `claude-channel` command is installed by `claude-plus`.

```bash
claude-channel                   # show status + available updates
claude-channel list              # list recent releases with dates
claude-channel latest            # switch to latest (bleeding edge)
claude-channel stable            # switch to stable
claude-channel pin 2.1.105       # freeze to specific version
claude-channel upgrade           # update to newest of current channel
claude-channel inspect 2.1.114   # show changelog for a version
```

Switching channels resolves the version, updates the cask, reinstalls, and syncs to GitHub:

```bash
$ claude-channel latest
Latest: 2.1.116
Reinstalling...
Synced to GitHub.
```

### Pinning a version

Pin to any version published to Anthropic's CDN:

```bash
claude-channel pin 2.1.100
```

### Inspecting a version

View the changelog for any release:

```bash
$ claude-channel inspect 2.1.114
Claude Code 2.1.114
===================

Released: 2026-04-18

## What's changed
- Fixed a crash in the permission dialog when an agent teams teammate...
```

## Upgrading

```bash
brew upgrade claude-code
```

This checks the livecheck URL for your tracked channel and upgrades if a newer version is available.

## Uninstall

```bash
claude-setup undo               # if claude-plus is installed
brew uninstall claude-code
```
