cask "scout" do
  version "0.1.0-beta.4"
  sha256 "e66115eeb0a30d6048bf8994efa9120341d79d2bc40d2ee74ae3257dbd647290"

  url "https://github.com/jackspirou/scout/releases/download/v#{version}/Scout.dmg"
  name "Scout"
  desc "Native macOS file manager built with Swift and AppKit"
  homepage "https://github.com/jackspirou/scout"

  app "Scout.app"

  zap trash: [
    "~/Library/Application Support/Scout",
    "~/Library/Preferences/com.jackspirou.scout.plist",
  ]
end
