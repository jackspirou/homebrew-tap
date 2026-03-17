cask "scout" do
  version "0.1.0-beta.3"
  sha256 "9a1e6ac45ecaa49e1126a13f3a56ec2f3ae008a17c8a47cccb9e73b466f347bb"

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
