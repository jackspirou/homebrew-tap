class ClaudeAutomode < Formula
  desc "Enables auto mode for Claude Code with Opus/Sonnet 4.6 on Max plan"
  homepage "https://github.com/jackspirou/homebrew-tap"
  head "https://github.com/jackspirou/homebrew-tap.git", branch: "main"
  license "MIT"

  depends_on "fswatch"
  depends_on "jq"

  def install
    # Get dependency paths
    fswatch_bin = Formula["fswatch"].opt_bin/"fswatch"
    jq_bin = Formula["jq"].opt_bin/"jq"

    # Create the daemon script with full paths
    (bin/"claude-automode-daemon").write <<~EOS
      #!/bin/bash
      # Daemon that watches ~/.claude.json and re-patches auto mode whenever it changes
      #
      # Usage:
      #   claude-automode-daemon &        # Run in background
      #   claude-automode-daemon --once   # Patch once and exit

      CLAUDE_CONFIG="$HOME/.claude.json"
      PATCH_VALUE='enabled'
      JQ="#{jq_bin}"
      FSWATCH="#{fswatch_bin}"

      patch_config() {
          if [ -f "$CLAUDE_CONFIG" ]; then
              current=$("$JQ" -r '.cachedGrowthBookFeatures.tengu_auto_mode_config.enabled // "disabled"' "$CLAUDE_CONFIG" 2>/dev/null)
              if [ "$current" != "$PATCH_VALUE" ]; then
                  "$JQ" '.cachedGrowthBookFeatures.tengu_auto_mode_config.enabled = "enabled"' "$CLAUDE_CONFIG" > "${CLAUDE_CONFIG}.tmp" 2>/dev/null && \\
                  mv "${CLAUDE_CONFIG}.tmp" "$CLAUDE_CONFIG" && \\
                  echo "[$(date '+%H:%M:%S')] Patched auto mode: $current -> $PATCH_VALUE"
              fi
          fi
      }

      # Initial patch
      patch_config

      if [ "$1" = "--once" ]; then
          exit 0
      fi

      echo "Watching $CLAUDE_CONFIG for changes... (Ctrl+C to stop)"

      # Use fswatch for efficient file watching
      "$FSWATCH" -0 "$CLAUDE_CONFIG" 2>/dev/null | while read -d "" event; do
          sleep 0.1  # Debounce
          patch_config
      done
    EOS
    chmod 0755, bin/"claude-automode-daemon"

    # Create wrapper that patches and runs claude
    (bin/"claude-auto").write <<~EOS
      #!/bin/bash
      # Wrapper for Claude Code that enables auto mode with Opus 4.6 on Max plan
      #{bin}/claude-automode-daemon --once
      exec claude --permission-mode auto "$@"
    EOS
    chmod 0755, bin/"claude-auto"
  end

  def caveats
    <<~EOS
      To enable auto mode persistence, start the background service:
        brew services start claude-automode

      Or run manually:
        claude-automode-daemon &

      You can also use the wrapper command:
        claude-auto

      To make claude-auto the default, add to your ~/.zshrc:
        alias claude='claude-auto'
    EOS
  end

  service do
    run [opt_bin/"claude-automode-daemon"]
    keep_alive true
    log_path var/"log/claude-automode.log"
    error_log_path var/"log/claude-automode.log"
  end

  test do
    system "#{bin}/claude-automode-daemon", "--once"
  end
end
