cask "scout" do
  version :latest
  sha256 :no_check

  url "https://github.com/jackspirou/scout/releases/latest/download/Scout.dmg"
  name "Scout"
  desc "Native macOS file manager built with Swift and AppKit"
  homepage "https://github.com/jackspirou/scout"

  app "Scout.app"

  zap trash: [
    "~/Library/Preferences/com.jackspirou.scout.plist",
  ]
end
