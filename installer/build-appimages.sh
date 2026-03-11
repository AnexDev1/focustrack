#!/bin/bash
# Build AppImage packages for various distributions using linuxdeploy/AppImageKit.
# Requires flutter build linux has already been run.

set -euo pipefail

cd "$(dirname "$0")/.."  # repo root

# make sure we have a fresh linux bundle
flutter build linux --release

# paths
dist_dir="installer/dist"
bundle_dir="build/linux/x64/release/bundle"

# common name
over=0.1.0
arch=$(uname -m)

mkdir -p "$dist_dir"

# Ensure linuxdeploy and appimagetool are installed or download them.
# You can get them from https://github.com/linuxdeploy/linuxdeploy/releases
# and https://github.com/AppImage/AppImageKit/releases

linuxdeploy=${LINUXDEPLOY:-$(which linuxdeploy || true)}
appimagetool=${APPIMAGETOOL:-$(which appimagetool || true)}

if [[ -z "$linuxdeploy" || -z "$appimagetool" ]]; then
    echo "Please install linuxdeploy and appimagetool and ensure they are on PATH."
    exit 1
fi

# create an AppDir skeleton
appdir="FocusTrack.AppDir"
rm -rf "$appdir"
mkdir -p "$appdir/usr/bin"
cp -r "$bundle_dir"/* "$appdir/usr/bin/"
# create a desktop file
cat > "$appdir/focustrack.desktop" <<'EOF'
[Desktop Entry]
Name=FocusTrack
Exec=focustrack
Icon=focustrack
Type=Application
Categories=Utility;
EOF

# copy icon
cp lib/assets/target.png "$appdir/focustrack.png"  # adjust path to icon

# run linuxdeploy to generate AppImage
chmod +x "$appdir/usr/bin/focustrack"

# one AppImage works across most distros; separate target packages not needed
$linuxdeploy --appdir "$appdir" --output appimage

# move result
mv *.AppImage "$dist_dir/FocusTrack-${over}-linux-${arch}.AppImage"

# cleanup
rm -rf "$appdir"

echo "AppImage generated at $dist_dir/FocusTrack-${over}-linux-${arch}.AppImage"
