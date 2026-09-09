cask "cmdx" do
  version "1.6.0-pre2"
  sha256 "52fccb90e754ca1a2a2824c9c015f5e2ced7f7a544758968ed9ee0ca8adf6575"

  url "https://github.com/YONN2222/cmdX/releases/download/#{version}/cmdX-#{version}.dmg"
  name "cmdX"
  desc "Adds missing Cmd+X (cut) functionality to Finder"
  homepage "https://github.com/YONN2222/cmdX"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates false

  app "cmdX.app"

  caveats <<~EOS
    cmdX needs Accessibility permission under System Settings → Privacy & Security → Accessibility.
  EOS
end
