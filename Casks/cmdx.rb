cask "cmdx" do
  version "1.4"
  sha256 "bf339266d5961e1c7bf3a0fafcf22c6d7ca09fb5c11df9d958ae5c6d20809d18"

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
