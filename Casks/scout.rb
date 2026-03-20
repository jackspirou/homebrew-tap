cask "scout" do
  version "0.1.0-beta.13"
  sha256 "1ce08c14c78e2713ff0398d63e1adb9cfd089dc300f47b1919748a176b857a63"

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
