# Install Layout

zvm uses one PATH directory:

```text
~/.zvm/bin
```

That directory contains zvm itself and the active Zig symlink:

```text
~/.zvm/bin/zvm
~/.zvm/bin/zig -> ../versions/0.15.2-esp.r4/zig
```

Installed toolchains live under:

```text
~/.zvm/versions/<version>/
```

There is no shims directory. Switching versions replaces the `~/.zvm/bin/zig` symlink and records the selected version in `~/.zvm/current`.
