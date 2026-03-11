# Build The FocusTrack Windows Installer

## Requirements

- Flutter SDK installed and on PATH
- Chocolatey installed
- Inno Setup installed or installable with `choco install innosetup -y`

## Build Steps

1. Build the Flutter Windows release:
   `flutter build windows --release`
2. Compile the installer:
   `& "C:\Users\hp\Tools\Inno Setup 6\ISCC.exe" installer\FocusTrack.iss`

The setup executable will be written to `installer\dist\FocusTrack-Setup-1.1.0.exe`.

> **Note:** there is also a companion Linux packaging script.  See
> `BUILD_LINUX_INSTALLER.md` if you'd like to build a tarball for GitHub
> releases.
