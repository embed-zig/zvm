# zvm — Zig 版本管理器

[![CI](https://github.com/embed-zig/zvm/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/embed-zig/zvm/actions/workflows/ci.yml)

[English](README.md) | **中文**

> 用一个 symlink 管理 Zig 版本。没有 shims，没有 shell 钩子，没有依赖。

`zvm` 可以安装和切换官方 Zig 版本以及 ESP Zig bootstrap 构建版本。它用 Zig 编写，但以预编译二进制形式发布——安装 zvm 本身不需要 Zig。

## 快速开始

```sh
# 安装 zvm
curl -fsSL https://github.com/embed-zig/zvm/releases/latest/download/install.sh | sh

# 加入 PATH
export PATH="$HOME/.zvm/bin:$PATH"

# 安装并使用 Zig
zvm install 0.15.2
zvm use 0.15.2
zig version
```

## 特性

- **单 symlink 设计** — 没有 shims 目录，只有一个 `~/.zvm/bin/zig` 软链接
- **模式匹配** — 使用 `zvm install '0.15.2-esp.*'` 安装最新匹配的版本
- **ESP bootstrap 支持** — 原生支持 `embed-zig/esp-zig-bootstrap` 发布版本
- **跨平台** — 在 Linux (x86_64, aarch64)、macOS (Intel, Apple Silicon) 和 Windows 上测试
- **自包含** — 预编译二进制，没有运行时依赖

## 可用命令

```sh
zvm list-remote              # 列出所有可用版本
zvm list-remote '0.15.*'   # 使用模式过滤
zvm install 0.15.2         # 安装特定版本
zvm install '0.15.2-esp.*' # 安装最新 ESP 构建版本
zvm use 0.15.2             # 切换当前版本
zvm current                # 显示当前版本
zvm env                    # 打印 PATH 导出命令
zvm doctor                 # 检查安装状态
```

## 工作原理

```text
~/.zvm/
├── bin/
│   ├── zvm              # 版本管理器
│   └── zig -> ../versions/0.15.2/zig
└── versions/
    ├── 0.15.2/
    │   └── zig
    └── 0.15.2-esp.r4/
        └── zig
```

`zvm use <version>` 原子性地更新 `~/.zvm/bin/zig` 软链接。除了 PATH 之外不需要其他 shell 集成。

## 版本模式

zvm 支持基于 SemVer 的模式匹配：


| 模式             | 解析为                 |
| -------------- | ------------------- |
| `0.15.2`       | 精确版本                |
| `0.15.2-esp.*` | 0.15.2 的最新 ESP 构建版本 |
| `0.16.*`       | 最新的 0.16.x 发布版本     |


官方发布版本使用标准 SemVer (`0.15.2`)。ESP 构建版本使用预发布标识符 (`0.15.2-esp.r4`)。

## 文档

- [安装指南](docs/zh/installation.md) — 详细安装选项
- [Shell 设置](docs/zh/shell-integration.md) — PATH 配置
- [目录布局](docs/zh/install-layout.md) — 文件组织方式
- [Registry 格式](docs/zh/registry-format.md) — 添加新版本
- [Agent Skill](docs/zh/agent-skill.md) — 用于 Cursor/windsurf 代理

## 更新 zvm

```sh
# curl 安装
zvm self-update

# Homebrew
brew upgrade zvm
```

## 开发

```sh
zig build              # 构建 zvm
zig build test         # 运行测试
./devtools/verify-registry.sh
```

开发期间设置 `ZVM_REGISTRY_DIR` 以使用自定义 registry 进行测试。