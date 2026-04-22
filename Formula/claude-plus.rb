class ClaudePlus < Formula
  desc "Auto mode, channel switching, and setup tools for Claude Code"
  homepage "https://github.com/jackspirou/homebrew-tap"
  head "https://github.com/jackspirou/homebrew-tap.git", branch: "main"
  license "MIT"

  depends_on "jq"
  depends_on "node"
  depends_on "openssl"

  def install
    jq_bin = Formula["jq"].opt_bin/"jq"
    node_bin = Formula["node"].opt_bin/"node"
    openssl_bin = Formula["openssl"].opt_bin/"openssl"

    # Install claude-channel, claude-brew.sh, and automode proxy from source
    bin.install "bin/claude-channel"
    (share/"claude-plus").install "etc/claude-brew.sh"
    (share/"claude-plus").install "etc/automode-proxy.js"

    # Generate proxy launcher (generates certs if needed, runs proxy in foreground)
    proxy_js = opt_share/"claude-plus/automode-proxy.js"
    (bin/"claude-automode-proxy").write <<~BASH
      #!/bin/bash
      CERT_DIR="$HOME/.claude/automode-proxy"
      KEY="$CERT_DIR/key.pem"
      CERT="$CERT_DIR/cert.pem"
      PORT="${AUTOMODE_PROXY_PORT:-18019}"

      # Generate certs if missing
      if [ ! -f "$KEY" ] || [ ! -f "$CERT" ]; then
          mkdir -p "$CERT_DIR"
          "#{openssl_bin}" req -x509 -newkey rsa:2048 -keyout "$KEY" -out "$CERT" \\
              -days 3650 -nodes -subj "/CN=api.anthropic.com" \\
              -addext "subjectAltName=DNS:api.anthropic.com" 2>/dev/null
      fi

      exec env AUTOMODE_PROXY_KEY="$KEY" AUTOMODE_PROXY_CERT="$CERT" AUTOMODE_PROXY_PORT="$PORT" \\
          "#{node_bin}" "#{proxy_js}"
    BASH
    chmod 0755, bin/"claude-automode-proxy"

    # Generate wrapper that ensures proxy is running + runs claude with auto mode
    (bin/"claude-auto").write <<~BASH
      #!/bin/bash
      PROXY_PORT="${AUTOMODE_PROXY_PORT:-18019}"
      PIDFILE="$HOME/.claude/automode-proxy/proxy.pid"

      # Start proxy if not already running
      if ! { [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; }; then
          #{opt_bin}/claude-automode-proxy &
          PROXY_PID=$!
          mkdir -p "$(dirname "$PIDFILE")"
          echo "$PROXY_PID" > "$PIDFILE"
          sleep 0.3
      fi

      # Run claude through the proxy
      NODE_TLS_REJECT_UNAUTHORIZED=0 \\
      HTTPS_PROXY="http://127.0.0.1:$PROXY_PORT" \\
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

          # Auto mode config
          local jq="#{jq_bin}"
          local config="$HOME/.claude.json"
          if [ -f "$config" ]; then
              local enabled=$("$jq" -r '.cachedGrowthBookFeatures.tengu_auto_mode_config.enabled // "disabled"' "$config" 2>/dev/null)
              echo "  automode: $enabled (cached)"
          else
              echo "  automode: no config found"
          fi

          # Proxy
          local pidfile="$HOME/.claude/automode-proxy/proxy.pid"
          local proxy_pid=""
          if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
              proxy_pid=$(cat "$pidfile")
          else
              proxy_pid=$(pgrep -f "automode-proxy.js" 2>/dev/null | head -1)
          fi
          if [ -n "$proxy_pid" ]; then
              echo "  proxy:    running (pid $proxy_pid)"
          else
              echo "  proxy:    stopped"
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

          # Start proxy via brew service
          brew services start claude-plus 2>/dev/null || true
          echo "  ✓ Proxy started"

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

          # Stop proxy
          brew services stop claude-plus 2>/dev/null || true
          local pidfile="$HOME/.claude/automode-proxy/proxy.pid"
          if [ -f "$pidfile" ]; then
              kill "$(cat "$pidfile")" 2>/dev/null || true
              rm -f "$pidfile"
          fi
          echo "  ✓ Proxy stopped"

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
    (bin/"claude-automode-proxy").chmod 0755
  end

  def caveats
    <<~EOS
      Run the setup command:

        claude-setup

      This starts the auto mode proxy and adds shell aliases.
      Run `claude-setup status` to check state, `claude-setup undo` to revert.
    EOS
  end

  service do
    run [opt_bin/"claude-automode-proxy"]
    keep_alive true
    log_path var/"log/claude-plus.log"
    error_log_path var/"log/claude-plus.log"
  end

  test do
    assert_match "automode-proxy", (bin/"claude-auto").read
  end
end
