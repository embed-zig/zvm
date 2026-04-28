# Registry Format

The registry is a flat directory of ZON files describing available Zig versions.

## File Layout

```
registry/
├── 0.15.2.zon
├── 0.15.2-esp.r4.zon
├── 0.16.0-esp.r1.zon
├── 0.16.0.zon
└── 0.17.0-dev.135+9df02121d.zon
```

Each file is named `<version>.zon`. The version must be valid SemVer.

## Schema

```zig
.{
    .version = "0.15.2-esp.r4",
    .channel = "esp",           // "official" or "esp"
    .date = "2026-04-19",       // ISO 8601 date
    .upstream = .{
        .kind = "github_release",
        .repo = "embed-zig/esp-zig-bootstrap",
        .tag = "v0.15.2-r4",
    },
    .notes = "ESP Zig bootstrap 0.15.2 r4",
    .platforms = .{
        .{
            .target = "macos-aarch64",
            .url = "https://github.com/.../zig-0.15.2-r4-aarch64-macos-none-baseline.tar.xz",
            .sha256 = "be60072b64f64f6074145875f9f73cebf699484f43053b7e9292efd1bd5c75d5",
            .size = 53935208,
        },
        // ... more platforms
    },
}
```

## Version Naming

**Official releases** use canonical SemVer:

- `0.15.2`
- `0.16.0`
- `0.17.0-dev.135+9df02121d`

**ESP builds** use pre-release identifiers:

- `0.15.2-esp.r4` (r4 release for 0.15.2)
- `0.16.0-esp.r1` (r1 release for 0.16.0)

## Platform Targets

Official Zig releases must include all six targets:

- `macos-x86_64`
- `macos-aarch64`
- `linux-x86_64`
- `linux-aarch64`
- `windows-x86_64`
- `windows-aarch64`

ESP releases must include at least one target, and may only include platforms actually published by the upstream release.

## Adding a New Version

1. Create `registry/<version>.zon`
2. Fill in all fields with real upstream URLs
3. Run `./devtools/verify-registry.sh` to validate
4. Commit the file

## Pattern Matching

zvm resolves patterns to the highest SemVer precedence match:


| Pattern        | Matches                   | Example result            |
| -------------- | ------------------------- | ------------------------- |
| `0.15.2`       | Exact                     | `0.15.2`                  |
| `0.15.2-esp.`* | All ESP builds for 0.15.2 | `0.15.2-esp.r4` (highest) |
| `0.16.*`       | All 0.16.x releases       | `0.16.0` (highest)        |
| `0.17.*`       | All 0.17.x releases       | `0.17.0-dev.135+...`      |


