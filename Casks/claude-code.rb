cask "claude-code" do
  arch arm: "arm64", intel: "x64"
  os macos: "darwin", linux: "linux"

  version "2.1.98"
  sha256 :no_check

  url "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/#{version}/#{os}-#{arch}/claude",
      verified: "storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/"
  name "Claude Code"
  desc "Terminal-based AI coding assistant with auto mode patch for Opus 4.6"
  homepage "https://www.anthropic.com/claude-code"

  caveats <<~EOS
    For auto mode with Opus 4.6 on Max plan, also install:
      brew install jackspirou/tap/claude-automode
      brew services start claude-automode
  EOS

  livecheck do
    url "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/latest"
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  binary "claude"

  postflight do
    # Patch GrowthBook cache to enable auto mode with Opus 4.6 on Max plan
    claude_config = File.expand_path("~/.claude.json")
    if File.exist?(claude_config)
      require "json"
      config = JSON.parse(File.read(claude_config))
      config["cachedGrowthBookFeatures"] ||= {}
      config["cachedGrowthBookFeatures"]["tengu_auto_mode_config"] ||= {}
      config["cachedGrowthBookFeatures"]["tengu_auto_mode_config"]["enabled"] = "enabled"
      File.write(claude_config, JSON.pretty_generate(config))
    end
  end

  zap trash: [
        "~/.cache/claude",
        "~/.claude.json*",
        "~/.config/claude",
        "~/.local/bin/claude",
        "~/.local/share/claude",
        "~/.local/state/claude",
        "~/Library/Caches/claude-cli-nodejs",
      ],
      rmdir: "~/.claude"
end
