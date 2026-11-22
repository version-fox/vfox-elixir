[中文](zh-CN/link.md) | [English](link.md)

# Using Elixir that is already on the machine

If Elixir is already installed by the system, asdf, mise, Homebrew, Scoop or the official installer, `vfox link --detect elixir` can adopt it instead of installing another copy. It needs vfox 1.1.0 or later (`vfox --version`).

```bash
vfox link --detect elixir
```

vfox lists what the plugin found and asks which ones to link:

```
Found:
  elixir@1.16.2-otp-26  /path/to/asdf/installs/elixir/1.16.2-otp-26  (installed by asdf)
Link 1 elixir installation(s)?
```

`vfox link --detect -y elixir` links everything without asking. Without a terminal, such as in CI, `-y` is required.

After linking, use the version as usual: `vfox use -g elixir@1.16.2-otp-26`. `vfox uninstall` on a linked version removes only the link. The Elixir installation stays where it is.

vfox skips a candidate when a version with the same name is already installed, when the name is an alias, or when its directory is already linked.

## What it looks for

On Linux and macOS:

- `$HOME/.asdf/installs/elixir`: each subdirectory, named after the directory (asdf).
- `$MISE_DATA_DIR/installs/elixir`, or `$HOME/.local/share/mise/installs/elixir` when `MISE_DATA_DIR` is not set: each subdirectory, named after the directory (mise).
- Homebrew: the Elixir kegs, such as `elixir`, in `/opt/homebrew/opt`, `/usr/local/opt`, `/home/linuxbrew/.linuxbrew/opt` and `$HOME/.linuxbrew/opt`. A keg keeps its files under `libexec`, which is looked at first. The name is the version in its `VERSION` file, or in `lib/elixir/ebin/elixir.app`.
- `/usr/lib/elixir` and `/usr/local/lib/elixir`: each is an install root itself, such as the Elixir from a Linux package manager.
- Each subdirectory of `/usr/local` and `/opt`.
- The `elixir` command on `PATH`, after resolving symbolic links.

On Windows:

- `%USERPROFILE%\scoop\apps\elixir`: each subdirectory (Scoop). The name comes from `VERSION`.
- `%LOCALAPPDATA%\mise\installs\elixir`: each subdirectory, named after the directory (mise).
- `%ProgramFiles%\Elixir`, `%ProgramFiles(x86)%\Elixir` and `%LOCALAPPDATA%\Programs\Elixir`: each is an install root itself. The name comes from `VERSION`.
- Every line of `where elixir`.

A directory is an install root when it contains `bin/elixir` (Windows: `bin\elixir.bat`), and either a `VERSION` file or `lib/elixir/ebin/elixir.app`.

The name is:

- For asdf and mise, the directory name, such as `1.16.2-otp-26`.
- Otherwise the content of `VERSION`, or the version in `lib/elixir/ebin/elixir.app` when there is no `VERSION` file.

A name must start with a letter or digit, contain only letters, digits, `.`, `_`, `+` and `-`, and it cannot be `latest`. Other installations are skipped.

The plugin never reports vfox's own installs under `.vfox` or `.version-fox`, or under `VFOX_HOME`, because vfox already manages them. The same path is reported once, and so is the same name. The first one found wins. The list is sorted by name.

The note after each entry says where the install was found, such as `installed by asdf`, `system Elixir` or `found on PATH`. The note is for information only. Use the name with `vfox use`.

## Linking by hand

Where detection does not look, link the install root yourself. The install root is the directory that holds `bin/` and either `VERSION` or `lib/elixir/ebin/elixir.app`:

```bash
vfox link elixir@1.16.2-otp-26 /path/to/elixir
vfox use -g elixir@1.16.2-otp-26
```

A name for `vfox link` may contain letters, digits, `.`, `_`, `+` and `-`, must start with a letter or digit, and cannot be `latest`. vfox checks that the `bin` directory holds a command before it links.
