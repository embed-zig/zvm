# Agent Skill

The zvm skill at `skills/zvm/SKILL.md` helps Cursor/windsurf agents manage Zig installations.

## Requirements

- Install zvm before relying on the skill for Zig operations.
- Install Node.js (`npm`/`npx`) before installing the skill with the Skills CLI.
- The skill is published from this repository and can be installed globally with `npx skills`.

## What the Skill Does

- Checks if zvm is installed, installs if missing
- Updates zvm via `self-update` or Homebrew
- Installs and switches Zig versions
- Verifies PATH configuration

## Quick Start (Human Users)

Install zvm first:

```sh
curl -fsSL https://github.com/embed-zig/zvm/releases/latest/download/install.sh | sh
```

Install the agent skill globally:

```sh
npx skills add embed-zig/zvm --skill zvm -g -y
```

Verify both pieces:

```sh
export PATH="$HOME/.zvm/bin:$PATH"
zvm --version
npx skills list -g
```

## Quick Start (AI Agent)

If you are an AI Agent helping a user set up zvm, complete these steps:

```sh
# 1. Install zvm
curl -fsSL https://github.com/embed-zig/zvm/releases/latest/download/install.sh | sh

# 2. Install the zvm skill globally
npx skills add embed-zig/zvm --skill zvm -g -y

# 3. Verify the CLI
export PATH="$HOME/.zvm/bin:$PATH"
zvm --version
zvm doctor
```

If the user already has zvm installed, skip step 1 and only install/update the skill.

## Installing From a Local Checkout

During development, verify skill discovery from the repository root:

```sh
npx skills add . --list
```

Install the local checkout globally:

```sh
npx skills add . --skill zvm -g -y
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