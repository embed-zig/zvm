# Shell Integration

zvm requires minimal shell setup. Just add `~/.zvm/bin` to PATH.

## Quick Setup

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

## Verification

```sh
which zvm      # Should show ~/.zvm/bin/zvm
which zig      # Should show ~/.zvm/bin/zig
zig version    # Should print active Zig version
```

## Using zvm env

The `zvm env` command prints the correct PATH export for your current setup:

```sh
$ zvm env
export PATH="/home/user/.zvm/bin:$PATH"
```

Use this to copy-paste into your shell config, or eval directly:

```sh
eval "$(zvm env)"
```

## Custom Install Directory

If you installed zvm to a non-standard location:

```sh
export ZVM_HOME=/opt/zvm
export PATH="$ZVM_HOME/bin:$PATH"
```

## Troubleshooting

`**zvm: command not found**`

- Check that `~/.zvm/bin/zvm` exists
- Verify PATH includes `~/.zvm/bin`
- Try `source ~/.bashrc` (or `~/.zshrc`)

`**zig: command not found**`

- Run `zvm doctor` to check the symlink
- Ensure you've run `zvm use <version>` at least once

**Wrong Zig version**

- Check `zvm current` shows the expected version
- Run `zvm use <version>` to switch

