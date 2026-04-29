# Agent Skill

The zvm skill at `skills/zvm/SKILL.md` helps Cursor/windsurf agents manage Zig installations.

## What the Skill Does

- Checks if zvm is installed, installs if missing
- Updates zvm via `self-update` or Homebrew
- Installs and switches Zig versions
- Verifies PATH configuration

## Installing the Skill

Install zvm first:

```sh
curl -fsSL https://github.com/embed-zig/zvm/releases/latest/download/install.sh | sh
```

Then install the agent skill globally:

```sh
npx skills add embed-zig/zvm --skill zvm -g -y
```

## For Skill Authors

Keep the skill concise and operational:

- **Do** include specific command sequences for common tasks
- **Do** link to project docs for registry format details
- **Don't** duplicate full documentation in the skill file
- **Do** mention environment variables like `ZVM_HOME`

## Example Workflows

The skill guides agents through workflows like:

1. **Setup check**: Verify zvm exists → Check PATH → Install if needed
2. **Version install**: List remote → Resolve pattern → Install → Use
3. **Troubleshooting**: Run `zvm doctor` → Check symlink → Verify permissions

See `skills/zvm/SKILL.md` for the complete workflow definitions.