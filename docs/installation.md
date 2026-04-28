# Installation

zvm is installed as a prebuilt binary. Users do not need Zig to install zvm.

```sh
curl -fsSL https://raw.githubusercontent.com/embed-zig/zvm/main/install.sh | sh
```

The installer supports:

- `ZVM_VERSION`: release tag to install, default `latest`
- `ZVM_INSTALL_DIR`: installation root, default `$HOME/.zvm`
- `ZVM_REPO`: GitHub repository, default `embed-zig/zvm`
- `ZVM_ARTIFACT_DIR`: local release artifact directory, used by CI integration tests

It downloads `zvm-<os>-<arch>.tar.gz` and `SHA256SUMS` from GitHub Releases, verifies the checksum, and writes the binary to:

```text
~/.zvm/bin/zvm
```

Then add the bin directory to your shell PATH:

```sh
export PATH="$HOME/.zvm/bin:$PATH"
```

If zvm was installed with Homebrew, use:

```sh
brew upgrade zvm
```
