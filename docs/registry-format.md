# Registry Format

The registry is flat. Each version has one ZON file:

```text
registry/<version>.zon
```

Examples:

```text
registry/0.15.2.zon
registry/0.15.2-esp.r4.zon
registry/0.16.0.zon
registry/0.17.0-dev.135+9df02121d.zon
```

There are no source subdirectories, stable aliases, or latest aliases yet.

## Version Rules

Official Zig releases use canonical SemVer such as `0.15.2`.

ESP bootstrap builds use legal SemVer prerelease names such as:

```text
0.15.2-esp.r4
```

zvm supports simple pattern expressions such as:

```text
0.15.2-esp.*
0.17.*
```

Patterns are zvm-specific matchers, not registry aliases. They resolve to the highest SemVer precedence match among registry entries.

## Supported Host Targets

Each registry entry must include these host targets:

```text
macos-x86_64
macos-aarch64
linux-x86_64
linux-aarch64
windows-x86_64
windows-aarch64
```

## Schema

```zig
.{
    .version = "0.15.2-esp.r4",
    .channel = "esp",
    .date = "2026-04-01",
    .notes = "Human-readable notes.",
    .platforms = .{
        .{
            .target = "macos-aarch64",
            .url = "https://github.com/embed-zig/esp-zig-bootstrap/releases/download/v0.15.2-r4/zig-0.15.2-r4-aarch64-macos-none-baseline.tar.xz",
            .sha256 = "64 lowercase hex characters",
            .size = 53935208,
        },
    },
}
```

Registry entries must use real upstream URLs, sizes, and SHA-256 checksums. Run `./devtools/verify-registry.sh` before pushing registry changes.
