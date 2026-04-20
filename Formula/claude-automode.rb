class ClaudeAutomode < Formula
  desc "Enables auto mode for Claude Code with 4.5/4.6 models on Max plan"
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
      JQ="#{jq_bin}"
      FSWATCH="#{fswatch_bin}"

      # Models to enable for auto mode (4.5 and 4.6 families)
      ALLOWED_MODELS='["claude-opus-4-5","claude-sonnet-4-5","claude-haiku-4-5","claude-opus-4-6","claude-sonnet-4-6","claude-haiku-4-6"]'

      patch_config() {
          if [ -f "$CLAUDE_CONFIG" ]; then
              needs_patch=false

              # Check if enabled flag needs patching
              current_enabled=$("$JQ" -r '.cachedGrowthBookFeatures.tengu_auto_mode_config.enabled // "disabled"' "$CLAUDE_CONFIG" 2>/dev/null)
              if [ "$current_enabled" != "enabled" ]; then
                  needs_patch=true
              fi

              # Check if allowModels needs patching
              current_models=$("$JQ" -r '.cachedGrowthBookFeatures.tengu_auto_mode_config.allowModels // empty' "$CLAUDE_CONFIG" 2>/dev/null)
              if [ -z "$current_models" ] || [ "$current_models" = "null" ]; then
                  needs_patch=true
              fi

              if [ "$needs_patch" = true ]; then
                  "$JQ" --argjson models "$ALLOWED_MODELS" '
                      .cachedGrowthBookFeatures.tengu_auto_mode_config.enabled = "enabled" |
                      .cachedGrowthBookFeatures.tengu_auto_mode_config.allowModels = $models
                  ' "$CLAUDE_CONFIG" > "${CLAUDE_CONFIG}.tmp" 2>/dev/null && \\
                  mv "${CLAUDE_CONFIG}.tmp" "$CLAUDE_CONFIG" && \\
                  echo "[$(date '+%H:%M:%S')] Patched auto mode: enabled + allowModels for 4.5/4.6 families"
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

    # Create wrapper that ensures watcher is running and runs claude with auto mode
    (bin/"claude-auto").write <<~EOS
      #!/bin/bash
      # Wrapper for Claude Code that enables auto mode with 4.5/4.6 models on Max plan

      # Ensure watcher is running (handles all patching)
      if ! pgrep -qf claude-automode-daemon; then
          # Patch once for immediate use, then start watcher for persistence
          #{bin}/claude-automode-daemon --once
          brew services start claude-automode 2>/dev/null &
      fi

      exec claude --permission-mode auto "$@"
    EOS
    chmod 0755, bin/"claude-auto"
  end

  def caveats
    <<~EOS
      Add to your ~/.zshrc:

        alias claude='claude-auto'

      That's it. The watcher service starts automatically when needed.

      Manual control:
        brew services start claude-automode   # start watcher
        brew services stop claude-automode    # stop watcher
        claude-auto                           # run with auto mode
        \\claude                               # run without auto mode
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
