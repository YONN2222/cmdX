cask "cmdx" do
  version "1.6.2"
  sha256 "5d7e2db97fc2172cabe43f7ec97260996c3c813bff94cd32e91e489619e608ec"

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

  postflight_steps do
    if_path_exists "{{appdir}}/cmdX.app" do
      run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/cmdX.app"]
    end
  end

  uninstall quit: "com.yonn2222.cmdX"

  zap trash: [
    "~/Library/Caches/com.yonn2222.cmdX",
    "~/Library/HTTPStorages/com.yonn2222.cmdX",
    "~/Library/LaunchAgents/com.yonn2222.cmdX.loginitem.plist",
    "~/Library/Preferences/com.yonn2222.cmdX.plist",
  ]

  caveats <<~EOS
    cmdX needs Accessibility permission under System Settings → Privacy & Security → Accessibility.
  EOS
end
