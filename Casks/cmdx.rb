cask "cmdx" do
  version "1.6.0-pre4"
  sha256 "2ce0ad465ee0a3ecc54e93598acb4adde6d732629bcc8e0f3c7e34b9f9350c6c"

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
