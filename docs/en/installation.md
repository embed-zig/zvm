# Installation

zvm is distributed as prebuilt binaries. No existing Zig installation required.

## Requirements

- zvm itself requires only `curl`, `tar`, and a POSIX-like shell for the installer.
- Zig is not required to install zvm.
- Node.js (`npm`/`npx`) is only required for installing the optional AI Agent Skill.

## One-Line Install

```sh
curl -fsSL https://github.com/embed-zig/zvm/releases/latest/download/install.sh | sh
```

The installer:

1. Detects your OS and architecture
2. Downloads `zvm-<os>-<arch>.tar.gz` from GitHub Releases
3. Verifies SHA-256 checksum against `SHA256SUMS`
4. Extracts to `~/.zvm/bin/zvm`
5. Adds `~/.zvm/bin` to existing shell startup files when possible

## Environment Variables


| Variable           | Description                       | Default         |
| ------------------ | --------------------------------- | --------------- |
| `ZVM_VERSION`      | Release tag to install            | `latest`        |
| `ZVM_INSTALL_DIR`  | Installation root                 | `$HOME/.zvm`    |
| `ZVM_REPO`         | GitHub repository                 | `embed-zig/zvm` |
| `ZVM_ARTIFACT_DIR` | Local artifact directory (for CI) | —               |
| `ZVM_NO_MODIFY_PATH` | Skip existing shell startup file updates when set to `1` | — |


Example with custom directory:

```sh
curl -fsSL https://github.com/embed-zig/zvm/releases/latest/download/install.sh | ZVM_INSTALL_DIR=/usr/local/zvm sh
```

To install a specific release, download that release's `install.sh`:

```sh
curl -fsSL https://github.com/embed-zig/zvm/releases/download/v0.2.2/install.sh | sh
```

## AI Agent Skill

For skills.sh-compatible AI agent workflows, install zvm first, then install the skill globally:

```sh
curl -fsSL https://github.com/embed-zig/zvm/releases/latest/download/install.sh | sh
npx skills add embed-zig/zvm --skill zvm -g -y
```

The skill teaches agents how to install, update, use, and troubleshoot zvm. See [Agent Skill](agent-skill.md).

## Homebrew

```sh
# Install (requires manual tap until published)
brew tap embed-zig/zvm https://github.com/embed-zig/zvm
brew install zvm

# Update
brew upgrade zvm
```

## Windows

On Windows, install via Git Bash or WSL:

```sh
curl -fsSL https://github.com/embed-zig/zvm/releases/latest/download/install.sh | sh
```

Or manually:

1. Download `zvm-windows-x86_64.tar.gz` from [Releases](https://github.com/embed-zig/zvm/releases)
2. Extract to `C:\Users\<you>\.zvm\bin\`
3. Add `%USERPROFILE%\.zvm\bin` to PATH

## Verification

After installation:

```sh
export PATH="$HOME/.zvm/bin:$PATH"  # or restart your shell
zvm --version    # Should print version
zvm env          # Prints PATH export line
zvm doctor       # Full health check
```

## Updating

```sh
zvm self-update      # For curl installs
brew upgrade zvm     # For Homebrew installs
```

