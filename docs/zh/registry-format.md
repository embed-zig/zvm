# Registry 格式

Registry 是一个扁平的 ZON 文件目录，描述可用的 Zig 版本。

## 文件布局

```
registry/
├── 0.15.2.zon
├── 0.15.2-esp.r4.zon
├── 0.15.2-esp.r5.zon
├── 0.15.2-esp.r6.zon
├── 0.16.0-esp.r1.zon
├── 0.16.0-esp.r2.zon
├── 0.16.0-esp.r3.zon
├── 0.16.0.zon
└── 0.17.0-dev.135+9df02121d.zon
```

每个文件命名为 `<version>.zon`。版本必须是有效的 SemVer。

## Schema

```zig
.{
    .version = "0.15.2-esp.r6",
    .channel = "esp",           // "official" 或 "esp"
    .date = "2026-05-17",       // ISO 8601 日期
    .upstream = .{
        .kind = "github_release",
        .repo = "embed-zig/esp-zig-bootstrap",
        .tag = "v0.15.2-r6",
    },
    .notes = "ESP Zig bootstrap 0.15.2 r6",
    .platforms = .{
        .{
            .target = "macos-aarch64",
            .url = "https://github.com/.../zig-v0.15.2-r6-aarch64-macos-none-baseline.tar.xz",
            .sha256 = "8042f2faa1283182f9e50ef171a6779d2b83b1d0a64d8ac93465627620c06a63",
            .size = 52966312,
        },
        // ... 更多平台
    },
}
```

## 版本命名

**官方发布版本** 使用标准 SemVer：

- `0.15.2`
- `0.16.0`
- `0.17.0-dev.135+9df02121d`

**ESP 构建版本** 使用预发布标识符：

- `0.15.2-esp.r6`（0.15.2 的 r6 发布版本）
- `0.16.0-esp.r3`（0.16.0 的 r3 发布版本）

## 平台目标

官方 Zig 发布版本必须包含全部六个目标：

- `macos-x86_64`
- `macos-aarch64`
- `linux-x86_64`
- `linux-aarch64`
- `windows-x86_64`
- `windows-aarch64`

ESP 发布版本必须包含至少一个目标，并且只能包含上游 release 实际发布的平台。

## 添加新版本

1. 创建 `registry/<version>.zon`
2. 用真实的上游 URL 填写所有字段
3. 运行 `./devtools/verify-registry.sh` 验证
4. 提交文件

## 模式匹配

zvm 将模式解析为 SemVer 优先级最高的匹配项：


| 模式             | 匹配项                 | 示例结果                 |
| -------------- | ------------------- | -------------------- |
| `0.15.2`       | 精确匹配                | `0.15.2`             |
| `0.15.2-esp.`* | 0.15.2 的所有 ESP 构建版本 | `0.15.2-esp.r6`（最高）  |
| `0.16.`*       | 所有 0.16.x 发布版本      | `0.16.0`（最高）         |
| `0.17.*`       | 所有 0.17.x 发布版本      | `0.17.0-dev.135+...` |
