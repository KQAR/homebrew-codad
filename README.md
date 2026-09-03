# homebrew-codad

Homebrew tap for **codad-server**, the macOS host daemon behind the codad iOS app.

```sh
brew tap KQAR/codad
brew install codad-server
brew services start codad-server
codad-server pair            # prints the QR the app scans
```

Without Homebrew — installs to `~/.local/bin`, registers a LaunchAgent, nothing runs as
root, and it refuses rather than quietly producing a second copy:

```sh
curl -fsSL https://github.com/KQAR/homebrew-codad/releases/latest/download/install.sh | sh
```

Options through that pipe need `sh -s --`, since the script is on sh's stdin and not in its
arguments: `| sh -s -- --dry-run`, `--force`, `--no-service`, `--uninstall`.

Upgrade with `brew upgrade codad-server`; the daemon restarts under `brew services` on its
own. Uninstall with `brew services stop codad-server && brew uninstall codad-server` — that
leaves `~/.codad` (the host key and the paired devices) in place, so removing it is a
separate, deliberate `rm -rf ~/.codad`.

## What it does

The daemon attaches to the [Herdr](https://herdr.dev) sessions already running on your
machine and offers them to the phone over a pinned QUIC link on `udp/51820`. It never starts
a session of its own, and there is no cloud hop: the phone talks to your machine, over your
LAN or over Tailscale. Pairing is a QR — a single-use 60-second token plus the host key
fingerprint — and a device is taken back with `codad-server revoke`.

## Requirements

- macOS 26 or newer (Apple silicon or Intel; the binary is universal)
- Herdr, if you want panes — a machine with no multiplexer still pairs and still answers

## Notes

codad is closed source, so this tap ships a prebuilt binary rather than a source build.
Third-party taps may do that; homebrew-core may not, which is the whole reason this
repository exists. Only the compiled daemon and this formula are published here.

Builds up to and including 0.0.1 are signed ad-hoc rather than with a Developer ID, which
means macOS asks for local network permission again after each upgrade.
