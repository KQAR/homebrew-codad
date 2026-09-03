# codad-server — the macOS host daemon behind the codad iOS app.
#
# Binary-only, because codad is closed source. That is why this tap exists at all: a
# third-party tap may ship a prebuilt archive, homebrew-core may not. The tarball is cut by
# `server/release.sh` in the app repo and its version is `Wire.version` — the same string the
# daemon announces in `hello`, so this formula cannot claim a version the daemon denies.
class CodadServer < Formula
  desc "Host daemon for codad: drive the coding agents on your Mac from your phone"
  homepage "https://github.com/KQAR/homebrew-codad"
  url "https://github.com/KQAR/homebrew-codad/releases/download/v0.0.1/codad-server-0.0.1-universal.tar.gz"
  version "0.0.1"
  sha256 "72f76560c4b1cf144cd2047c212e4c0c043fd667c8f93bb5f258f2f7fcd6e07a"

  # Package.swift's floor: Network.framework's QUIC is what carries the wire, and the daemon
  # is macOS-only by measurement rather than preference (ARCHITECTURE.md).
  depends_on macos: :tahoe

  # Herdr and Orca are *discovered* at runtime and never launched by codad — a machine with
  # neither still pairs and still answers. So neither is a dependency here.

  def install
    bin.install "codad-server"
  end

  service do
    run [opt_bin/"codad-server", "run"]
    keep_alive true
    log_path var/"log/codad-server.log"
    error_log_path var/"log/codad-server.log"
    # Never root. The daemon reads this user's Keychain, ~/.codad and the agent settings
    # under ~/.claude; as root it would read the wrong ones and write files the user cannot.
    require_root false
  end

  def caveats
    <<~EOS
      Run it at login, and pair a phone:

        brew services start codad-server
        codad-server pair            # prints the QR the app scans

      It listens on udp/51820 and attaches to the Herdr sessions you already run — it never
      starts a session of its own. Its state, including the host key, is in ~/.codad.

      This build is signed ad-hoc, not with a Developer ID, so macOS asks for local network
      permission again after every upgrade.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/codad-server --help")
  end
end
