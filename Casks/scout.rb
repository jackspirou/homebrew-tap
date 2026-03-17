cask "scout" do
  version "0.1.0-beta.10"
  sha256 "08a0ee5b3ea842987da5c0fa3951e1a9fa5b5ca19ef8dc95612207b00759a675"

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
