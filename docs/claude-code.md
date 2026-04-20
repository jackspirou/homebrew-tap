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
claude-channel status            # show current version and channels
claude-channel latest            # switch to latest (bleeding edge)
claude-channel stable            # switch to stable
claude-channel version 2.1.105   # pin to specific version
claude-channel livecheck stable  # change what brew upgrade tracks
claude-channel sync              # push cask changes to GitHub
```

Each channel command resolves the version, updates the cask, and reinstalls:

```bash
$ claude-channel latest
Latest channel resolves to: 2.1.114
Cask version set to 2.1.114
Livecheck now tracks: latest

Reinstalling...
```

### Pinning a version

Pin to any version published to Anthropic's CDN:

```bash
claude-channel version 2.1.100
```

Pinning does not change the livecheck channel, so `brew upgrade` will still move you forward. To freeze completely:

```bash
claude-channel version 2.1.100
claude-channel livecheck stable
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
