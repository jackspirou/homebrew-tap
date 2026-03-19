cask "scout" do
  version "0.1.0-beta.11"
  sha256 "3e6c274c43dbb0a0beb8a650299fd7be1ad629b664d2f229a340812c72363e80"

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
