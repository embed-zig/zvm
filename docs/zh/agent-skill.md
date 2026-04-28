# Agent Skill

zvm skill 位于 `skills/zvm/SKILL.md`，帮助 Cursor/windsurf 代理管理 Zig 安装。

## Skill 功能

- 检查 zvm 是否已安装，如未安装则自动安装
- 通过 `self-update` 或 Homebrew 更新 zvm
- 安装和切换 Zig 版本
- 验证 PATH 配置

## 安装 Skill

```sh
npx skills add zvm
```

或手动将 `skills/zvm/` 复制到您的 agent skills 目录。

## 给 Skill 作者的建议

保持 skill 简洁实用：

- **要** 包含常见任务的特定命令序列
- **要** 链接到项目文档了解 registry 格式详情
- **不要** 在 skill 文件中重复完整文档
- **要** 提及 `ZVM_HOME` 等环境变量

## 示例工作流

Skill 指导代理完成以下工作流：

1. **设置检查**：验证 zvm 存在 → 检查 PATH → 如需则安装
2. **版本安装**：列出远程版本 → 解析模式 → 安装 → 使用
3. **故障排除**：运行 `zvm doctor` → 检查软链接 → 验证权限

完整的工作流定义参见 `skills/zvm/SKILL.md`。