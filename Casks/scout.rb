cask "scout" do
  version "0.1.0-beta.12"
  sha256 "14de341e5cec414e08e404077806d60542c16d7f34789a26285faaad3a23c98c"

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
