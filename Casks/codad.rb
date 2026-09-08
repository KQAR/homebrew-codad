# codad — the macOS host daemon, in the menu bar.
#
# This is `cask.rb.in`: `server/release.sh` fills in the version, the url and the sha256 and
# writes the result to `server/dist/codad.rb`, which is what goes into `Casks/codad.rb` in the
# tap. It is templated *here*, beside the app, for the same reason `install.sh.in` is: the
# caveats and the `zap` list describe what this app does to the machine, and they have to
# change in the commit that changes it, not in another repository afterwards.
#
# A cask rather than a formula because this is an app bundle. `Formula/codad-server.rb` stays
# where it is and ships the CLI — the two are the same daemon, and a machine may want either.
#
# The stanza order below is Homebrew's, not a preference: `brew style`'s Cask/StanzaOrder cop
# rejects any other, and `livecheck` in particular belongs above `depends_on`.
cask "codad" do
  version "0.0.1"
  sha256 "5e822151e85a186e22b4158c570d93ef999103b95096ae5590b06133e39d127e"

  # `#{version}` rather than the whole URL spelled out: `brew audit` reads a url that does not
  # mention the version as an *unversioned* one and asks for `sha256 :no_check`, which would
  # mean shipping an image nothing checks. The tag is substituted whole because a packaging
  # revision moves it and not the version (`server/release.sh --revision=`).
  url "https://github.com/KQAR/homebrew-codad/releases/download/v0.0.1/codad-#{version}.dmg"
  name "codad"
  # No platform in a cask's description — `brew style`'s Cask/Desc cop rejects "Mac", which
  # is how the formula next door words the same sentence.
  desc "Drive your coding agents from your phone"
  homepage "https://github.com/KQAR/homebrew-codad"

  # A packaging revision is a suffix on the *tag*, never on the version — the same binary
  # under a new tag is what `server/release.sh --revision=` cuts, because a published asset is
  # never replaced. Homebrew's default check reads the latest release's tag literally and then
  # reports `0.0.1` as out of date against `0.0.1-3`; this regex drops the suffix so a
  # revision is invisible here, exactly as it is to `brew info`.
  livecheck do
    url :url
    regex(/^v?(\d+(?:\.\d+)*)(?:-\d+)?$/i)
  end

  # Package.swift's floor. Network.framework's QUIC is what carries the wire, and the daemon
  # is macOS-only by measurement rather than preference (ARCHITECTURE.md). A bare symbol
  # means "this or newer"; the `">= :tahoe"` string form is deprecated and Homebrew says so.
  depends_on macos: :tahoe

  app "codad.app"

  # Quit it before the bundle is replaced. A running copy holds udp/51820 and the keychain
  # its TLS key lives in; swapping the bundle underneath leaves a process whose code is no
  # longer on disk. And the login item is the app's own **Start at Login** switch
  # (`SMAppService.mainApp`), which would otherwise be left pointing at an app that is gone.
  uninstall quit:       "tech.fintopia.codad.server",
            login_item: "codad"

  # `~/.codad` is the host key, the phones' enrolments and the tunnel key — everything a
  # paired phone pinned. It is in `zap`, which is opt-in (`brew uninstall --zap`), and not in
  # `uninstall`, precisely because throwing it away means pairing every phone again.
  zap trash: [
    "~/.codad",
    "~/Library/Preferences/tech.fintopia.codad.server.plist",
  ]

  caveats do
    <<~EOS
      This build is signed ad-hoc, not with a Developer ID, so Gatekeeper will refuse the
      copy Homebrew just quarantined — as "damaged", which it is not. Either install it
      unquarantined:

        brew install --cask --no-quarantine KQAR/codad/codad

      or clear the flag on the copy you have:

        xattr -dr com.apple.quarantine /Applications/codad.app

      Then open it. It lives in the menu bar and has no Dock icon; use **Pairing code…** in
      its menu and scan that with codad on your phone.

      It serves udp/51820 and attaches to the Herdr and Orca sessions you already run — it
      never starts one of its own. Its state, including the host key, is in ~/.codad.

      Do not run it beside `brew services start codad-server`: one port, and a listener that
      would share it rather than refuse it. The app looks before it binds and will tell you
      whose port it is, with an offer to take it over.
    EOS
  end
end
