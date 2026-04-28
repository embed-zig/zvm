# 目录布局

zvm 将所有内容放在一个目录下：`~/.zvm`

## 结构

```text
~/.zvm/
├── bin/
│   ├── zvm                 # zvm 可执行文件
│   └── zig -> ../versions/0.15.2/zig   # 当前激活的 Zig 软链接
├── versions/
│   ├── 0.15.2/
│   │   └── zig             # Zig 二进制文件
│   ├── 0.15.2-esp.r4/
│   │   └── zig
│   └── ...
├── tmp/                    # 下载缓存
└── current                 # 记录当前版本的文本文件
```

## 关键文件

- `~/.zvm/bin/zvm` — 版本管理器本身
- `~/.zvm/bin/zig` — 指向当前激活 Zig 版本的软链接
- `~/.zvm/versions/<version>/zig` — 实际的 Zig 二进制文件
- `~/.zvm/current` — 包含当前版本字符串的纯文本文件

## 设计说明

**没有 shims 目录。** 与某些版本管理器不同，zvm 不使用装满包装脚本的目录。`~/.zvm/bin/zig` 软链接直接指向所选版本的二进制文件。

**原子切换。** `zvm use <version>` 以原子方式更新软链接，因此不会出现 `zig` 指向空的情况。

**版本隔离。** 每个安装的工具链位于自己的 `versions/<version>/` 目录中。删除一个版本只需要 `rm -rf ~/.zvm/versions/0.15.2/`。

## 自定义位置

设置 `ZVM_HOME` 以使用不同的基础目录：

```sh
export ZVM_HOME=/opt/zvm
zvm install 0.15.2    # 安装到 /opt/zvm/versions/0.15.2/
```

这对系统范围安装或 CI 环境很有用。
