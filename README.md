# zvm — Zig Version Manager

[![CI](https://github.com/embed-zig/zvm/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/embed-zig/zvm/actions/workflows/ci.yml)

**English** | [中文](README.zh.md)

> Manage Zig toolchains with a single symlink. No shims, no shell hooks, no dependencies.

`zvm` installs and switches between official Zig releases and ESP Zig bootstrap builds. It's written in Zig but distributed as prebuilt binaries; installing zvm itself does not require Zig.

[Install](#installation--quick-start) · [Agent Skill](#agent-skill) · [Commands](#available-commands) · [Version Patterns](#version-patterns) · [Docs](#documentation)

## Installation & Quick Start

### Requirements

- No Zig installation is required to install or use zvm.
- `curl`, `tar`, and a POSIX-like shell are required for the installer.
- Node.js (`npm`/`npx`) is only required if you want to install the AI Agent Skill.

### Quick Start (Human Users)

```sh
# Install zvm
curl -fsSL https://github.com/embed-zig/zvm/releases/latest/download/install.sh | sh

# Restart your shell, or update PATH for the current session
export PATH="$HOME/.zvm/bin:$PATH"

# Install and use Zig
zvm install 0.15
zvm use 0.15
zig version
```

### Quick Start (AI Agents)

If you are an AI agent helping the user set up zvm, install zvm first, then install the skill globally with the Skills CLI:

```sh
# Install CLI
curl -fsSL https://github.com/embed-zig/zvm/releases/latest/download/install.sh | sh

# Install CLI Skill
npx skills add embed-zig/zvm --skill zvm -g -y

# Verify
export PATH="$HOME/.zvm/bin:$PATH"
zvm --version
zvm doctor
```

The skill installation requires Node.js because it uses `npx skills`. The zvm binary itself does not depend on Node.js.

## Features

- **Single symlink design** — No shims directory, just one `~/.zvm/bin/zig` symlink
- **Pattern matching** — Install latest matching version with `zvm install 0.15`, `zvm install 0.15.2-esp`, or `zvm install '0.16.*'`
- **ESP bootstrap support** — First-class support for `embed-zig/esp-zig-bootstrap` releases
- **Cross-platform** — Tested on Linux (x86_64, aarch64), macOS (Intel, Apple Silicon), and Windows
- **Self-contained** — Prebuilt binaries, no runtime dependencies

## Available Commands

```sh
zvm list-remote              # List all available versions
zvm list-remote '0.15.*'    # Filter with pattern
zvm install 0.15            # Install latest 0.15.x release
zvm install 0.15.2-esp      # Install latest matching ESP build
zvm use 0.15                # Switch to latest installed 0.15.x version
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
    └── 0.15.2-esp.r5/
        └── zig
```

`zvm use <version>` atomically updates the `~/.zvm/bin/zig` symlink. No shell integration needed beyond PATH.

## Version Patterns

zvm supports SemVer-based pattern matching:


| Pattern        | Resolves to                 |
| -------------- | --------------------------- |
| `0.15.2`       | Exact version               |
| `0.15`         | Latest 0.15.x release      |
| `0`            | Latest 0.x release         |
| `0.15.2-esp`   | Latest 0.15.2 ESP build    |
| `0.15.2-esp.*` | Latest ESP build for 0.15.2 |
| `0.16.*`       | Latest 0.16.x release       |


Official releases use canonical SemVer (`0.15.2`). ESP builds use pre-release identifiers (`0.15.2-esp.r5`).

## Agent Skill

zvm also ships a [skills.sh](https://skills.sh)-compatible Agent Skill from `skills/zvm/SKILL.md`. Install zvm first, then install the skill:

```sh
curl -fsSL https://github.com/embed-zig/zvm/releases/latest/download/install.sh | sh
npx skills add embed-zig/zvm --skill zvm -g -y
```

The skill is discoverable by `npx skills add embed-zig/zvm --list`. Public installs through the Skills CLI allow it to appear in the skills.sh directory.

See [Agent Skill](docs/en/agent-skill.md) for details.

## Documentation

- [Installation](docs/en/installation.md) — Detailed install options
- [Shell Setup](docs/en/shell-integration.md) — PATH configuration
- [Directory Layout](docs/en/install-layout.md) — How files are organized
- [Registry Format](docs/en/registry-format.md) — Adding new versions
- [Agent Skill](docs/en/agent-skill.md) — For skills.sh-compatible AI agents

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
