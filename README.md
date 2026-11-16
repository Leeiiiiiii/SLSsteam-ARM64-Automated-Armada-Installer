# SLSsteam ARM64 – Armada Installer

An automated installer for **SLSsteam ARM64** on AYN Odin devices running Armada OS.

The installer handles archive extraction, library installation, configuration setup and integration with Armada's native Steam launcher.

## Requirements

- AYN Odin device running Armada OS (AArch64).
- `SLSsteam AArch64.7z` archive.
- `7z`, `7zz` or `bsdtar` installed.
- `sudo` access.

## Installation

1. Place `install-armada.sh` and `SLSsteam AArch64.7z` in your Downloads folder.
2. Open a terminal.
3. Run:

```bash
chmod +x install-armada.sh
./install-armada.sh
```

4. Enter your sudo password when requested.
5. Wait for installation and verification to finish.
6. Restart Steam through Armada.

## What the installer does

1. Searches for `SLSsteam AArch64.7z`.
2. Extracts the archive into a temporary directory.
3. Locates and verifies `SLSsteam.so` and `config.yaml`.
4. Installs the ARM64 library to:

   `~/.local/share/SLSsteam/SLSsteam.so`

5. Installs the configuration to:

   `~/.config/SLSsteam/config.yaml`

6. Preserves existing non-empty configuration files.
7. Runs `sudo ostree admin unlock --hotfix`.
8. Backs up Armada's Steam launcher.
9. Adds the following environment variable before Steam executes:

```bash
export LD_AUDIT="${HOME}/.local/share/SLSsteam/SLSsteam.so"
```

10. Verifies the installed library, SHA-256 checksum, configuration and launcher modification.

## After Armada updates

Armada updates may restore the original Steam launcher and remove the SLSsteam injection line.

If this happens, run the installer again to restore the integration.

## Important notes

- Designed for native ARM64 Steam on Armada OS.
- Does not install the generic x86-64 SLSsteam library.
- Does not modify Steam's executable.
- Does not overwrite an existing non-empty configuration.
- Creates a backup before modifying Armada's Steam launcher.
- Requires an OSTree hotfix unlock to modify the immutable launcher.
- Installation success does not independently guarantee that SLSsteam initializes correctly.

## Uninstallation

The installer currently does not include an automatic uninstall option.

To restore the original Armada launcher, use the backup created during installation. Remove the SLSsteam library and configuration separately if you also want to remove the user-level installation.

---

**Disclaimer:** This is a community installation script, not an official Armada or SLSsteam installer. Use at your own risk and retain your launcher backups.
