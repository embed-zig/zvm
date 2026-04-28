# zvm — Zig Version Manager

[![CI](https://github.com/embed-zig/zvm/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/embed-zig/zvm/actions/workflows/ci.yml)

**English** | [中文](README.zh.md)

> Manage Zig toolchains with a single symlink. No shims, no shell hooks, no dependencies.

`zvm` installs and switches between official Zig releases and ESP Zig bootstrap builds. It's written in Zig but distributed as prebuilt binaries—installing zvm itself does not require Zig.

## Quick Start

```sh
# Install zvm
curl -fsSL https://github.com/embed-zig/zvm/releases/latest/download/install.sh | sh

# Add to PATH
export PATH="$HOME/.zvm/bin:$PATH"

# Install and use Zig
zvm install 0.15.2
zvm use 0.15.2
zig version
```

## Features

- **Single symlink design** — No shims directory, just one `~/.zvm/bin/zig` symlink
- **Pattern matching** — Install latest matching version with `zvm install '0.15.2-esp.*'`
- **ESP bootstrap support** — First-class support for `embed-zig/esp-zig-bootstrap` releases
- **Cross-platform** — Tested on Linux (x86_64, aarch64), macOS (Intel, Apple Silicon), and Windows
- **Self-contained** — Prebuilt binaries, no runtime dependencies

## Available Commands

```sh
zvm list-remote              # List all available versions
zvm list-remote '0.15.*'   # Filter with pattern
zvm install 0.15.2         # Install a specific version
zvm install '0.15.2-esp.*' # Install latest ESP build
zvm use 0.15.2             # Switch active version
zvm current                # Show active version
zvm env                    # Print PATH export
zvm doctor                 # Check installation health
```

## How It Works

```text
~/.zvm/
├── bin/
│   ├── zvm              # The version manager
│   └── zig -> ../versions/0.15.2/zig
└── versions/
    ├── 0.15.2/
    │   └── zig
    └── 0.15.2-esp.r4/
        └── zig
```

`zvm use <version>` atomically updates the `~/.zvm/bin/zig` symlink. No shell integration needed beyond PATH.

## Version Patterns

zvm supports SemVer-based pattern matching:


| Pattern        | Resolves to                 |
| -------------- | --------------------------- |
| `0.15.2`       | Exact version               |
| `0.15.2-esp.*` | Latest ESP build for 0.15.2 |
| `0.16.*`       | Latest 0.16.x release       |


Official releases use canonical SemVer (`0.15.2`). ESP builds use pre-release identifiers (`0.15.2-esp.r4`).

## Documentation

- [Installation](docs/en/installation.md) — Detailed install options
- [Shell Setup](docs/en/shell-integration.md) — PATH configuration
- [Directory Layout](docs/en/install-layout.md) — How files are organized
- [Registry Format](docs/en/registry-format.md) — Adding new versions
- [Agent Skill](docs/en/agent-skill.md) — For Cursor/windsurf agents

## Updating zvm

```sh
# curl install
zvm self-update

# Homebrew
brew upgrade zvm
```

## Development

```sh
zig build              # Build zvm
zig build test         # Run tests
./devtools/verify-registry.sh
```

Set `ZVM_REGISTRY_DIR` to test with a custom registry during development.