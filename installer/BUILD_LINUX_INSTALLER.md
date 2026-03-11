# Build The FocusTrack Linux "Installer"

This repository currently ships a simple tarball containing the Linux release
bundle. You can upload the generated archive to GitHub releases and link it on
your landing page just like the Windows setup executable.

## Requirements

- Flutter SDK installed and on `PATH` **inside the same Linux/WSL
  environment.**  Flutter is not shared with Windows; install via `snap`
  (`sudo snap install flutter --classic`) or follow the manual Linux instructions
  at https://flutter.dev/docs/get-started/install/linux.
- A working Linux build environment (glibc, compiler toolchain, X11 libraries,
  etc.)
  - On Debian/Ubuntu/WSL this usually means installing `build-essential` and
    `libx11-dev`:

      ```bash
      sudo apt update
      sudo apt install build-essential libx11-dev
      ```

  - Other distributions provide similar packages (e.g. `base-devel` on
    Arch, `gcc-c++`/`libX11-devel` on Fedora).
- `tar`/`gzip` (these are standard on most distributions)

> **Note:** the packaging script must be run on Linux or inside WSL.  Running
> it on plain Windows will either fail or print an explanatory error.
>
> **WSL tip:** if your source tree is on `/mnt/c/...` the underlying NTFS
> mount doesn’t support Unix permission bits, so `chmod` won’t work.  Either
> invoke the script explicitly with `bash` or clone the repo into the WSL
> filesystem (`~/`) before building.

> **Optional:** you can adapt the script to create a `.deb`/`.rpm` or
> [AppImage](https://appimage.org/) if your project later needs a
> distribution-specific package.

## Build Steps

1. Build the Flutter Linux release bundle:
   ```bash
   flutter build linux --release
   ```

2. Run the packaging script:
   ```bash
   chmod +x installer/build-installer-linux.sh  # one-time
   ./installer/build-installer-linux.sh
   ```

The resulting archive will be written to `installer/dist/` with a name such as
`FocusTrack-0.1.0-linux-x86_64.tar.gz`.  You can attach this file to your GitHub
release assets and use the download link on your landing page.

#### Optional: AppImage

If you prefer a single-file distribution that runs on Ubuntu, Fedora, Arch,
etc., install `linuxdeploy` and `appimagetool` (see their GitHub releases)
and run the companion script:

```bash
chmod +x installer/build-appimages.sh
./installer/build-appimages.sh
```

This produces `installer/dist/FocusTrack-<version>-linux-<arch>.AppImage` and
will also copy it to the Windows path when run under WSL.

### Distributing/installing the tarball

End users simply extract and run the bundle.  A typical installation sequence:

```bash
# extract somewhere convenient (e.g. /opt or $HOME)
tar -C /opt -xzvf FocusTrack-0.1.0-linux-x86_64.tar.gz
# optionally add to PATH
sudo ln -s /opt/focustrack/focustrack /usr/local/bin/focustrack

# launch it
focustrack
```

No package system is required; the bundle is a self‑contained Linux executable
with its assets.  Alternatively you can run directly from the archive without
installing:

```bash
mkdir ~/focustrack-tmp
tar -xzf FocusTrack-0.1.0-linux-x86_64.tar.gz -C ~/focustrack-tmp
~/focustrack-tmp/focustrack
```

For GUI distributions you may also provide a `.desktop` file pointing at the
unpacked binary or symlink.

---

For comparison, the Windows installer build is documented in
`BUILD_WINDOWS_INSTALLER.md`.