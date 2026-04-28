# Shell Integration

Add zvm's bin directory to PATH:

```sh
export PATH="$HOME/.zvm/bin:$PATH"
```

For zsh:

```sh
echo 'export PATH="$HOME/.zvm/bin:$PATH"' >> ~/.zshrc
```

For bash:

```sh
echo 'export PATH="$HOME/.zvm/bin:$PATH"' >> ~/.bashrc
```

The CLI can print the export line for the active install root:

```sh
zvm env
```

If `ZVM_HOME` is set, zvm uses `$ZVM_HOME/bin` and `$ZVM_HOME/versions` instead of `$HOME/.zvm`.
