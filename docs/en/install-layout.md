# Directory Layout

zvm keeps everything under one directory: `~/.zvm`

## Structure

```text
~/.zvm/
├── bin/
│   ├── zvm                 # zvm executable
│   └── zig -> ../versions/0.15.2/zig   # Active Zig symlink
├── versions/
│   ├── 0.15.2/
│   │   └── zig             # Zig binary
│   ├── 0.15.2-esp.r4/
│   │   └── zig
│   └── ...
├── tmp/                    # Download cache
└── current                 # Text file with active version
```

## Key Files

- `~/.zvm/bin/zvm` — The version manager itself
- `~/.zvm/bin/zig` — Symlink to the active Zig version
- `~/.zvm/versions/<version>/zig` — Actual Zig binaries
- `~/.zvm/current` — Plain text file containing the active version string

## Design Notes

**No shims directory.** Unlike some version managers, zvm doesn't use a directory full of wrapper scripts. The `~/.zvm/bin/zig` symlink points directly to the selected version's binary.

**Atomic switching.** `zvm use <version>` updates the symlink atomically, so there's no moment where `zig` points to nothing.

**Version isolation.** Each installed toolchain lives in its own `versions/<version>/` directory. Deleting a version is just `rm -rf ~/.zvm/versions/0.15.2/`.

## Custom Location

Set `ZVM_HOME` to use a different base directory:

```sh
export ZVM_HOME=/opt/zvm
zvm install 0.15.2    # Installs to /opt/zvm/versions/0.15.2/
```

This is useful for system-wide installs or CI environments.