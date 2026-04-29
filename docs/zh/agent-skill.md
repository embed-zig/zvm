# Agent Skill

zvm skill 位于 `skills/zvm/SKILL.md`，帮助兼容 skills.sh 的 AI agents 管理 Zig 安装。

## 环境要求

- 在依赖 skill 执行 Zig 操作前，先安装 zvm。
- 使用 Skills CLI 安装 skill 前，需要安装 Node.js (`npm`/`npx`)。
- 该 skill 从本公开仓库分发，可通过 `npx skills` 全局安装。

## Skill 功能

- 检查 zvm 是否已安装，如未安装则自动安装
- 通过 `self-update` 或 Homebrew 更新 zvm
- 安装和切换 Zig 版本
- 验证 PATH 配置

## 快速开始（人类用户）

先安装 zvm：

```sh
curl -fsSL https://github.com/embed-zig/zvm/releases/latest/download/install.sh | sh
```

全局安装 agent skill：

```sh
npx skills add embed-zig/zvm --skill zvm -g -y
```

验证两部分都可用：

```sh
export PATH="$HOME/.zvm/bin:$PATH"
zvm --version
npx skills list -g
```

## 快速开始（AI Agents）

如果你是 AI Agent，正在帮助用户设置 zvm，按以下步骤执行：

```sh
# 1. 安装 zvm
curl -fsSL https://github.com/embed-zig/zvm/releases/latest/download/install.sh | sh

# 2. 全局安装 zvm skill
npx skills add embed-zig/zvm --skill zvm -g -y

# 3. 验证 CLI
export PATH="$HOME/.zvm/bin:$PATH"
zvm --version
zvm doctor
```

如果用户已经安装了 zvm，可以跳过第 1 步，只安装或更新 skill。

## skills.sh 可发现性

`skills.sh` 不需要单独的 publish 命令。只要 skill 位于公开仓库，并且能通过 Skills CLI 安装，就具备进入目录的条件。

验证仓库发现：

```sh
npx skills add embed-zig/zvm --list
```

从公开仓库安装：

```sh
npx skills add embed-zig/zvm --skill zvm -g -y
```

通过 Skills CLI 从公开仓库安装后，安装遥测会让该 skill 有机会出现在 skills.sh 目录中。如果是为了验证目录发现，不要设置 `DISABLE_TELEMETRY` 或 `DO_NOT_TRACK`。

## 从本地 checkout 安装

开发期间，在仓库根目录验证 skill 能被发现：

```sh
npx skills add . --list
```

从本地 checkout 全局安装：

```sh
npx skills add . --skill zvm -g -y
```

## 给 Skill 作者的建议

保持 skill 简洁实用：

- **要** 包含常见任务的特定命令序列
- **要** 链接到项目文档了解 registry 格式详情
- **不要** 在 skill 文件中重复完整文档
- **要** 保持 `name` 与父目录名一致（`zvm`）
- **要** 在 frontmatter 的 `description` 中保留触发关键词

## 示例工作流

Skill 指导代理完成以下工作流：

1. **设置检查**：验证 zvm 存在 → 检查 PATH → 如需则安装
2. **版本安装**：列出远程版本 → 解析模式 → 安装 → 使用
3. **故障排除**：运行 `zvm doctor` → 检查软链接 → 验证权限

完整的工作流定义参见 `skills/zvm/SKILL.md`。