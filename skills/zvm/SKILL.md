# zvm Agent Skill

Use this skill when a user wants to install, update, or operate zvm, the Zig Version Manager.

## Install zvm Itself

zvm is distributed as prebuilt release binaries. Users do not need Zig installed.

Preferred installer:

```sh
curl -fsSL https://github.com/embed-zig/zvm/releases/latest/download/install.sh | sh
```

Useful environment variables:

- `ZVM_VERSION`: release tag, default `latest`
- `ZVM_INSTALL_DIR`: install root, default `$HOME/.zvm`

The installer writes `zvm` to `$ZVM_INSTALL_DIR/bin/zvm`. Tell users to add `$ZVM_INSTALL_DIR/bin` to PATH.

## Update zvm Itself

Run:

```sh
zvm self-update
```

If zvm reports that it is Homebrew-managed, use:

```sh
brew upgrade zvm
```

## Install and Switch Zig Toolchains

List available versions:

```sh
zvm list-remote
zvm list-remote '0.15.2-esp.*'
```

Install and switch:

```sh
zvm install 0.15.2-esp.r4
zvm use 0.15.2-esp.r4
```

Verify:

```sh
zvm current
zig version
zvm doctor
```

zvm uses one PATH directory: `$HOME/.zvm/bin`. The active Zig is `$HOME/.zvm/bin/zig`, a symlink to `../versions/<version>/zig`.
