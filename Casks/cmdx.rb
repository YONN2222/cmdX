cask "cmdx" do
  version "1.6.0-pre1"
  sha256 "004e86f6b58c400663ed43e857753bfce86b92c060b0836171cd1a5da03663f0"

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
