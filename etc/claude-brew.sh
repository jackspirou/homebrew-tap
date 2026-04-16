# Claude Code brew wrapper
# Source this file in your shell profile (~/.zshrc or ~/.bashrc):
#   source "$(brew --repository)/Library/Taps/jackspirou/homebrew-tap/etc/claude-brew.sh"

brew() {
  case "$1" in
    upgrade|install|reinstall|info|uninstall)
      case "$2" in
        claude-code|cc)
          command brew "$1" jackspirou/tap/claude-code "${@:3}"
          return
          ;;
      esac
      ;;
  esac
  command brew "$@"
}
