class ClaudePlus < Formula
  desc "Auto mode, channel switching, and setup tools for Claude Code"
  homepage "https://github.com/jackspirou/homebrew-tap"
  head "https://github.com/jackspirou/homebrew-tap.git", branch: "main"
  license "MIT"

  def install
    # Install claude-channel and the brew wrapper from source
    bin.install "bin/claude-channel"
    (share/"claude-plus").install "etc/claude-brew.sh"

    # Generate wrapper that runs claude with auto mode
    (bin/"claude-auto").write <<~BASH
      #!/bin/bash
      # Run Claude Code with auto mode by default.
      exec claude --permission-mode auto "$@"
    BASH
    chmod 0755, bin/"claude-auto"

    # Generate setup command
    brew_sh = opt_share/"claude-plus/claude-brew.sh"
    (bin/"claude-setup").write <<~SETUP
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

          # Shell config
          if grep -q "$MARKER" "$SHELL_RC" 2>/dev/null; then
              echo "  shell:    configured ($(basename "$SHELL_RC"))"
          else
              echo "  shell:    not configured"
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
          echo "  To activate now, run:"
          echo ""
          echo "    source $SHELL_RC"
          echo ""
          echo "  Then:"
          echo "    claude          auto mode"
          echo "    \\\\claude         normal mode (bypass alias)"
          echo "    claude-channel  version/channel management"
          echo ""
      }

      undo() {
          echo "Claude Plus Undo"
          echo "================"
          echo ""

          # Remove shell config
          if grep -q "$MARKER" "$SHELL_RC" 2>/dev/null; then
              sed -i '' '/^# claude-plus/,/^# claude-plus/d' "$SHELL_RC"
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
    SETUP
    chmod 0755, bin/"claude-setup"
  end

  def post_install
    (bin/"claude-setup").chmod 0755
    (bin/"claude-auto").chmod 0755
  end

  def caveats
    <<~EOS
      Run the setup command:

        claude-setup

      This adds the shell alias and brew wrapper.
      Run `claude-setup status` to check state, `claude-setup undo` to revert.
    EOS
  end

  test do
    assert_match "--permission-mode auto", (bin/"claude-auto").read
  end
end
