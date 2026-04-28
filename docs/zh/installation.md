# 安装指南

zvm 以预编译二进制形式分发，不需要现有的 Zig 安装。

## 一行命令安装

```sh
curl -fsSL https://raw.githubusercontent.com/embed-zig/zvm/main/install.sh | sh
```

安装脚本的工作流程：

1. 检测操作系统和架构
2. 从 GitHub Releases 下载 `zvm-<os>-<arch>.tar.gz`
3. 根据 `SHA256SUMS` 校验 SHA-256 校验和
4. 解压到 `~/.zvm/bin/zvm`

## 环境变量


| 变量                 | 说明                    | 默认值             |
| ------------------ | --------------------- | --------------- |
| `ZVM_VERSION`      | 要安装的发布标签              | `latest`        |
| `ZVM_INSTALL_DIR`  | 安装根目录                 | `$HOME/.zvm`    |
| `ZVM_REPO`         | GitHub 仓库             | `embed-zig/zvm` |
| `ZVM_ARTIFACT_DIR` | 本地 artifact 目录（用于 CI） | —               |


使用自定义目录的示例：

```sh
ZVM_INSTALL_DIR=/usr/local/zvm curl -fsSL ... | sh
```

## Homebrew

```sh
# 安装（正式发布前需要手动添加 tap）
brew tap embed-zig/zvm https://github.com/embed-zig/zvm
brew install zvm

# 更新
brew upgrade zvm
```

## Windows

在 Windows 上，通过 Git Bash 或 WSL 安装：

```sh
curl -fsSL https://raw.githubusercontent.com/embed-zig/zvm/main/install.sh | sh
```

或手动安装：

1. 从 [Releases](https://github.com/embed-zig/zvm/releases) 下载 `zvm-windows-x86_64.tar.gz`
2. 解压到 `C:\Users\<用户名>\.zvm\bin\`
3. 将 `%USERPROFILE%\.zvm\bin` 加入 PATH

## 验证

安装完成后：

```sh
zvm --version    # 应输出版本号
zvm env          # 打印 PATH 导出命令
zvm doctor       # 完整健康检查
```

## 更新

```sh
zvm self-update      # curl 安装
brew upgrade zvm     # Homebrew 安装
```