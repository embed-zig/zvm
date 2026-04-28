# Shell 集成

zvm 只需要最少的 shell 设置。安装脚本会在找到已有 shell 启动文件时自动更新它们。安装后重启 shell，或执行安装脚本打印的 export 命令。

## 快速设置

只有在使用 `ZVM_NO_MODIFY_PATH=1` 安装，或想自定义 shell 文件时，才需要手动设置。

### Bash

```sh
echo 'export PATH="$HOME/.zvm/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Zsh

```sh
echo 'export PATH="$HOME/.zvm/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Fish

```sh
echo 'set -Ux PATH $HOME/.zvm/bin $PATH' >> ~/.config/fish/config.fish
```

## 验证

```sh
which zvm      # 应显示 ~/.zvm/bin/zvm
which zig      # 应显示 ~/.zvm/bin/zig
zig version    # 应输出当前 Zig 版本
```

## 使用 zvm env

`zvm env` 命令会打印适合您当前设置的 PATH 导出命令：

```sh
$ zvm env
export PATH="/home/user/.zvm/bin:$PATH"
```

可用于复制粘贴到 shell 配置中，或直接执行：

```sh
eval "$(zvm env)"
```

## 自定义安装目录

如果您将 zvm 安装到非标准位置：

```sh
export ZVM_HOME=/opt/zvm
export PATH="$ZVM_HOME/bin:$PATH"
```

## 故障排除

`**zvm: 找不到命令**`

- 检查 `~/.zvm/bin/zvm` 是否存在
- 确认 PATH 包含 `~/.zvm/bin`
- 尝试运行 `source ~/.bashrc`（或 `~/.zshrc`）

`**zig: 找不到命令**`

- 运行 `zvm doctor` 检查软链接状态
- 确保至少运行过一次 `zvm use <version>`

**Zig 版本不对**

- 检查 `zvm current` 显示的是否是预期版本
- 运行 `zvm use <version>` 切换版本