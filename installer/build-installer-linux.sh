#!/bin/bash
# Build a simple tarball "installer" for FocusTrack on Linux.
# This script is intended to be run on a Linux host (or inside WSL).
# It will fail silently on Windows since the tooling isn't available.

set -euo pipefail

# verify we're running on Linux otherwise bail with a friendly error
os=$(uname -s 2>/dev/null || echo unknown)
if [[ "$os" != "Linux" ]]; then
    echo "error: this packaging script must be run on Linux or WSL (current OS: $os)" >&2
    echo "       use a Linux machine or start WSL before invoking." >&2
    exit 1
fi

# change to project root (script lives in installer/)
cd "$(dirname "$0")/.."

# make sure flutter linux build is up to date
flutter build linux --release

# version extraction mirrors pubspec.yaml's version field
# strip any trailing CRs (pubspec.yaml may have Windows line endings)
version=$(grep '^version:' pubspec.yaml | awk '{print $2}' | tr -d '\r')
# strip any build metadata (e.g. 0.1.0+1)
version=${version%%+*}

arch=$(uname -m)

mkdir -p installer/dist

tarball="installer/dist/FocusTrack-${version}-linux-${arch}.tar.gz"

# package the release bundle
# the build output contains a "focustrack" executable and supporting files
tar -C build/linux/x64/release/bundle -czf "${tarball}" .

echo "Installer built at ${tarball}"

# if we're running under WSL and a mirror of the project exists on the
# Windows filesystem, copy the archive back so it's visible from Explorer.
# this is helpful when the repository is checked out on C: and you want the
# release asset on the Windows side.
if grep -qi microsoft /proc/version 2>/dev/null; then
    # get Windows username and strip CR/LF; wslpath could be used but
    # /mnt/c/Users/<user> is usually correct for a standard install.
    winuser=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n')
    winpath="/mnt/c/Users/${winuser}/focustrack/installer/dist"
    if [[ -d "$winpath" ]]; then
        echo "Copying installer to Windows path: $winpath"
        cp -v "${tarball}" "$winpath/" || true
    fi
fi
