# zvm

Zig Version Manager for official Zig releases and `embed-zig/esp-zig-bootstrap` builds.

- [中文](#中文)
- [English](#english)

## 中文

`zvm` 是一个 Zig 版本管理器。`zvm` 本体用 Zig 编写，但会以预编译 binary 的形式发布，所以用户安装 `zvm` 时不需要先安装 Zig。

当前仓库包含项目骨架、扁平 registry、安装布局和可构建的 CLI skeleton。Zig toolchain 的网络下载和解压逻辑还没有完整实现，但命令已经能解析 registry 版本并验证本地目录布局。

### 安装 zvm

```sh
curl -fsSL https://raw.githubusercontent.com/embed-zig/zvm/main/install.sh | sh
```

`install.sh` 会检测系统和 CPU 架构，从 GitHub Releases 下载匹配的 `zvm-<os>-<arch>.tar.gz`，用 `SHA256SUMS` 校验后安装到：

```text
~/.zvm/bin/zvm
```

把 `zvm` 加入 PATH：

```sh
export PATH="$HOME/.zvm/bin:$PATH"
```

如果通过 Homebrew 安装，更新时使用：

```sh
brew upgrade zvm
```

### 管理 Zig

```sh
zvm list-remote
zvm list-remote '0.15.2-esp.*'
zvm install 0.15.2
zvm use 0.15.2
zvm current
zvm env
zvm doctor
```

`zvm` 只使用一个 PATH 目录：

```text
~/.zvm/bin/zvm
~/.zvm/bin/zig -> ../versions/0.15.2-esp.r4/zig
~/.zvm/versions/0.15.2-esp.r4/
```

没有单独的 `shims` 目录。`zvm use <version>` 只更新 `~/.zvm/bin/zig` 这个 symlink。

### 版本命名

官方 Zig 使用标准 SemVer，例如 `0.15.2`。ESP bootstrap 使用合法的 SemVer pre-release 名称，例如 `0.15.2-esp.r4`。

`zvm` 支持简单的匹配表达式，例如 `0.15.2-esp.*`，并选择 SemVer 优先级最高的匹配版本。

### Registry

Registry 是扁平目录：

```text
registry/0.15.2.zon
registry/0.15.2-esp.r4.zon
registry/0.16.0.zon
registry/0.17.0-dev.135+9df02121d.zon
```

仓库内置的 registry 条目使用真实上游 URL、size 和 SHA-256 checksum，来源是 Zig download index 和 `embed-zig/esp-zig-bootstrap` GitHub Releases。

每个 registry 条目都包含 `macos-x86_64`、`macos-aarch64`、`linux-x86_64`、`linux-aarch64`、`windows-x86_64` 和 `windows-aarch64`。

### 开发

```sh
zig build
zig build test
sh -n install.sh devtools/*.sh
./devtools/verify-registry.sh
```

开发时可以用 `ZVM_REGISTRY_DIR` 指向另一个扁平 registry 目录。

## English

`zvm` is a Zig Version Manager. The `zvm` executable is written in Zig, but users install it as a prebuilt binary, so installing `zvm` itself does not require Zig.

This repository currently contains the project scaffold, flat registry, install layout, and a buildable CLI skeleton. Network download and extraction for Zig toolchains are not fully implemented yet, but commands already resolve registry versions and exercise the local layout.

### Install zvm

```sh
curl -fsSL https://raw.githubusercontent.com/embed-zig/zvm/main/install.sh | sh
```

`install.sh` detects OS and CPU architecture, downloads the matching `zvm-<os>-<arch>.tar.gz` from GitHub Releases, verifies it against `SHA256SUMS`, and installs it to:

```text
~/.zvm/bin/zvm
```

Add `zvm` to your shell path:

```sh
export PATH="$HOME/.zvm/bin:$PATH"
```

Homebrew-managed installs should update with:

```sh
brew upgrade zvm
```

### Manage Zig

```sh
zvm list-remote
zvm list-remote '0.15.2-esp.*'
zvm install 0.15.2
zvm use 0.15.2
zvm current
zvm env
zvm doctor
```

`zvm` uses a single PATH directory:

```text
~/.zvm/bin/zvm
~/.zvm/bin/zig -> ../versions/0.15.2-esp.r4/zig
~/.zvm/versions/0.15.2-esp.r4/
```

There is no separate `shims` directory. `zvm use <version>` only updates the `~/.zvm/bin/zig` symlink.

### Version Names

Official Zig releases use canonical SemVer such as `0.15.2`. ESP bootstrap builds use legal SemVer pre-release names such as `0.15.2-esp.r4`.

`zvm` supports simple pattern expressions such as `0.15.2-esp.*`; the highest SemVer precedence match is selected.

### Registry

Registry files are flat:

```text
registry/0.15.2.zon
registry/0.15.2-esp.r4.zon
registry/0.16.0.zon
registry/0.17.0-dev.135+9df02121d.zon
```

The checked-in registry entries use real upstream URLs, sizes, and SHA-256 checksums from the Zig download index and `embed-zig/esp-zig-bootstrap` GitHub Releases.

Each registry entry includes `macos-x86_64`, `macos-aarch64`, `linux-x86_64`, `linux-aarch64`, `windows-x86_64`, and `windows-aarch64`.

### Development

```sh
zig build
zig build test
sh -n install.sh devtools/*.sh
./devtools/verify-registry.sh
```

Use `ZVM_REGISTRY_DIR` to point the CLI at another flat registry directory while developing.
