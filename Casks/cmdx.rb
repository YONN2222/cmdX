cask "cmdx" do
  version "1.6.1"
  sha256 "307f27f1cfdd415f6fe9455fff1a6926fc4491169f4749884e7902fa23273ae3"

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
    app_path = appdir/"cmdX.app"
    next unless app_path.exist?
    system_command "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", app_path]
  end

  caveats <<~EOS
    cmdX needs Accessibility permission under System Settings → Privacy & Security → Accessibility.
  EOS
end
