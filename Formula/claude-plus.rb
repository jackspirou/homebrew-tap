class ClaudePlus < Formula
  desc "Auto mode, channel switching, and setup tools for Claude Code"
  homepage "https://github.com/jackspirou/homebrew-tap"
  head "https://github.com/jackspirou/homebrew-tap.git", branch: "main"
  license "MIT"

  depends_on "fswatch"
  depends_on "jq"

  def install
    fswatch_bin = Formula["fswatch"].opt_bin/"fswatch"
    jq_bin = Formula["jq"].opt_bin/"jq"

    # Install claude-channel and claude-brew.sh from source
    bin.install "bin/claude-channel"
    (share/"claude-plus").install "etc/claude-brew.sh"

    # Generate daemon script with full dependency paths
    (bin/"claude-automode-daemon").write <<~BASH
      #!/bin/bash
      CLAUDE_CONFIG="$HOME/.claude.json"
      JQ="#{jq_bin}"
      FSWATCH="#{fswatch_bin}"
      ALLOWED_MODELS='["claude-opus-4-5","claude-sonnet-4-5","claude-haiku-4-5","claude-opus-4-6","claude-sonnet-4-6","claude-haiku-4-6"]'

      patch_config() {
          [ -f "$CLAUDE_CONFIG" ] || return
          needs_patch=false
          current_enabled=$("$JQ" -r '.cachedGrowthBookFeatures.tengu_auto_mode_config.enabled // "disabled"' "$CLAUDE_CONFIG" 2>/dev/null)
          [ "$current_enabled" != "enabled" ] && needs_patch=true
          current_models=$("$JQ" -r '.cachedGrowthBookFeatures.tengu_auto_mode_config.allowModels // empty' "$CLAUDE_CONFIG" 2>/dev/null)
          [ -z "$current_models" ] || [ "$current_models" = "null" ] && needs_patch=true
          if [ "$needs_patch" = true ]; then
              "$JQ" --argjson models "$ALLOWED_MODELS" '
                  .cachedGrowthBookFeatures.tengu_auto_mode_config.enabled = "enabled" |
                  .cachedGrowthBookFeatures.tengu_auto_mode_config.allowModels = $models
              ' "$CLAUDE_CONFIG" > "${CLAUDE_CONFIG}.tmp" 2>/dev/null && \\
              mv "${CLAUDE_CONFIG}.tmp" "$CLAUDE_CONFIG" && \\
              echo "[$(date '+%H:%M:%S')] Patched auto mode: enabled + allowModels for 4.5/4.6 families"
          fi
      }

      patch_config
      [ "$1" = "--once" ] && exit 0
      echo "Watching $CLAUDE_CONFIG for changes..."
      "$FSWATCH" -0 "$CLAUDE_CONFIG" 2>/dev/null | while read -d "" event; do
          sleep 0.1
          patch_config
      done
    BASH
    chmod 0755, bin/"claude-automode-daemon"

    # Generate wrapper that ensures watcher + runs claude with auto mode
    (bin/"claude-auto").write <<~BASH
      #!/bin/bash
      if ! pgrep -qf claude-automode-daemon; then
          #{opt_bin}/claude-automode-daemon --once
          brew services start claude-plus 2>/dev/null &
      fi
      exec claude --permission-mode auto "$@"
    BASH
    chmod 0755, bin/"claude-auto"

    # Generate setup command
    brew_sh = opt_share/"claude-plus/claude-brew.sh"
    (bin/"claude-setup").write <<~BASH
      #!/bin/bash
      set -euo pipefail

      MARKER="# claude-plus"
      BREW_SH="#{brew_sh}"

      detect_shell_rc() {
          if [[ "$SHELL" == */zsh ]]; then echo "$HOME/.zshrc"
          elif [[ "$SHELL" == */bash ]]; then echo "$HOME/.bashrc"
          else echo "$HOME/.profile"
          fi
      }

      SHELL_RC="$(detect_shell_rc)"

      status() {
          echo "Claude Plus"
          echo "==========="
          echo ""

          # Binary
          if command -v claude &>/dev/null; then
              echo "  binary:   $(claude --version 2>/dev/null | head -1)"
          else
              echo "  binary:   not installed"
          fi

          # Auto mode
          local jq="#{jq_bin}"
          local config="$HOME/.claude.json"
          if [ -f "$config" ]; then
              local enabled=$("$jq" -r '.cachedGrowthBookFeatures.tengu_auto_mode_config.enabled // "disabled"' "$config" 2>/dev/null)
              local models=$("$jq" -r '.cachedGrowthBookFeatures.tengu_auto_mode_config.allowModels | length // 0' "$config" 2>/dev/null || echo "0")
              echo "  automode:  $enabled ($models models)"
          else
              echo "  automode:  no config found"
          fi

          # Watcher
          if pgrep -qf claude-automode-daemon 2>/dev/null; then
              echo "  watcher:   running"
          else
              echo "  watcher:   stopped"
          fi

          # Shell config
          if grep -q "$MARKER" "$SHELL_RC" 2>/dev/null; then
              echo "  shell:     configured ($(basename "$SHELL_RC"))"
          else
              echo "  shell:     not configured"
          fi

          echo ""
      }

      setup() {
          echo "Claude Plus Setup"
          echo "================="
          echo ""

          # Check binary
          if command -v claude &>/dev/null; then
              echo "  ✓ Claude binary found"
          else
              echo "  ✗ Claude binary not found"
              echo "    Install: brew install jackspirou/tap/claude-code"
              exit 1
          fi

          # Patch config
          #{opt_bin}/claude-automode-daemon --once 2>/dev/null
          echo "  ✓ Auto mode patched"

          # Start watcher
          brew services start claude-plus 2>/dev/null || true
          echo "  ✓ Watcher started"

          # Shell config (idempotent)
          if grep -q "$MARKER" "$SHELL_RC" 2>/dev/null; then
              echo "  ✓ Shell already configured ($(basename "$SHELL_RC"))"
          else
              cat >> "$SHELL_RC" <<SHELL

$MARKER — managed block, do not edit
alias claude='claude-auto'
source "$BREW_SH"
$MARKER — end
SHELL
              echo "  ✓ Shell configured ($(basename "$SHELL_RC"))"
          fi

          echo ""
          echo "  Done! Run: source $SHELL_RC"
          echo ""
          echo "  claude        auto mode (via alias)"
          echo "  \\\\claude       normal mode (bypass alias)"
          echo "  claude-channel  version/channel management"
          echo "  claude-setup status  check current state"
          echo ""
      }

      undo() {
          echo "Claude Plus Undo"
          echo "================"
          echo ""

          # Stop watcher
          brew services stop claude-plus 2>/dev/null || true
          echo "  ✓ Watcher stopped"

          # Remove shell config
          if grep -q "$MARKER" "$SHELL_RC" 2>/dev/null; then
              sed -i '' '/^# claude-plus/,/^# claude-plus/d' "$SHELL_RC"
              # Clean up any trailing blank lines left behind
              sed -i '' -e :a -e '/^\\n*$/{$d;N;ba' -e '}' "$SHELL_RC"
              echo "  ✓ Shell config removed from $(basename "$SHELL_RC")"
          else
              echo "  ✓ Shell config already clean"
          fi

          echo ""
          echo "  Done! Run: source $SHELL_RC"
          echo ""
      }

      case "${1:-}" in
          status) status ;;
          undo)   undo ;;
          "")     setup ;;
          *)      echo "Usage: claude-setup [status|undo]"; exit 1 ;;
      esac
    BASH
    chmod 0755, bin/"claude-setup"
  end

  def caveats
    <<~EOS
      Run the setup command:

        claude-setup

      This configures auto mode, starts the watcher, and adds shell aliases.
      Run `claude-setup status` to check state, `claude-setup undo` to revert.
    EOS
  end

  service do
    run [opt_bin/"claude-automode-daemon"]
    keep_alive true
    log_path var/"log/claude-plus.log"
    error_log_path var/"log/claude-plus.log"
  end

  test do
    system "#{bin}/claude-automode-daemon", "--once"
  end
end
