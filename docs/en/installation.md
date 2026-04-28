# Installation

zvm is distributed as prebuilt binaries. No existing Zig installation required.

## One-Line Install

```sh
curl -fsSL https://raw.githubusercontent.com/embed-zig/zvm/main/install.sh | sh
```

The installer:

1. Detects your OS and architecture
2. Downloads `zvm-<os>-<arch>.tar.gz` from GitHub Releases
3. Verifies SHA-256 checksum against `SHA256SUMS`
4. Extracts to `~/.zvm/bin/zvm`

## Environment Variables


| Variable           | Description                       | Default         |
| ------------------ | --------------------------------- | --------------- |
| `ZVM_VERSION`      | Release tag to install            | `latest`        |
| `ZVM_INSTALL_DIR`  | Installation root                 | `$HOME/.zvm`    |
| `ZVM_REPO`         | GitHub repository                 | `embed-zig/zvm` |
| `ZVM_ARTIFACT_DIR` | Local artifact directory (for CI) | —               |


Example with custom directory:

```sh
ZVM_INSTALL_DIR=/usr/local/zvm curl -fsSL ... | sh
```

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
curl -fsSL https://raw.githubusercontent.com/embed-zig/zvm/main/install.sh | sh
```

Or manually:

1. Download `zvm-windows-x86_64.tar.gz` from [Releases](https://github.com/embed-zig/zvm/releases)
2. Extract to `C:\Users\<you>\.zvm\bin\`
3. Add `%USERPROFILE%\.zvm\bin` to PATH

## Verification

After installation:

```sh
zvm --version    # Should print version
zvm env          # Prints PATH export line
zvm doctor       # Full health check
```

## Updating

```sh
zvm self-update      # For curl installs
brew upgrade zvm     # For Homebrew installs
```

