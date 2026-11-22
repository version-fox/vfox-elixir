[中文](link.md) | [English](../link.md)

# 使用本机已有的 Elixir

如果 Elixir 已经由系统、asdf、mise、Homebrew、Scoop 或官方安装器装在本机，`vfox link --detect elixir` 可以直接采用它，而不用再安装一份。需要 vfox 1.1.0 或更高版本（用 `vfox --version` 查看）。

```bash
vfox link --detect elixir
```

vfox 会列出插件找到的安装，并询问要链接哪些：

```
Found:
  elixir@1.16.2-otp-26  /path/to/asdf/installs/elixir/1.16.2-otp-26  (installed by asdf)
Link 1 elixir installation(s)?
```

`vfox link --detect -y elixir` 不询问，直接全部链接。在没有终端的环境（例如 CI）中，必须加 `-y`。

链接之后，照常使用即可：`vfox use -g elixir@1.16.2-otp-26`。对已链接的版本执行 `vfox uninstall`，只会删除链接，Elixir 本身留在原处。

以下情况 vfox 会跳过某个候选：同名版本已经安装、名字是某个别名、或者它的目录已经被链接。

## 查找的位置

Linux 和 macOS：

- `$HOME/.asdf/installs/elixir`：每个子目录，以目录名作为名字（asdf）。
- `$MISE_DATA_DIR/installs/elixir`；未设置 `MISE_DATA_DIR` 时为 `$HOME/.local/share/mise/installs/elixir`：每个子目录，以目录名作为名字（mise）。
- Homebrew：`/opt/homebrew/opt`、`/usr/local/opt`、`/home/linuxbrew/.linuxbrew/opt` 和 `$HOME/.linuxbrew/opt` 中的 Elixir keg，例如 `elixir`。keg 的文件放在 `libexec` 下，会先检查那里。名字取自 `VERSION` 文件中的版本，没有该文件时取 `lib/elixir/ebin/elixir.app` 中的版本。
- `/usr/lib/elixir` 和 `/usr/local/lib/elixir`：它们本身就是安装目录，例如 Linux 包管理器装的 Elixir。
- `/usr/local` 和 `/opt` 下的每个子目录。
- `PATH` 上的 `elixir` 命令，解析符号链接之后的位置。

Windows：

- `%USERPROFILE%\scoop\apps\elixir`：每个子目录（Scoop）。名字取自 `VERSION`。
- `%LOCALAPPDATA%\mise\installs\elixir`：每个子目录，以目录名作为名字（mise）。
- `%ProgramFiles%\Elixir`、`%ProgramFiles(x86)%\Elixir` 和 `%LOCALAPPDATA%\Programs\Elixir`：它们本身就是安装目录。名字取自 `VERSION`。
- `where elixir` 输出的每一行。

目录是否为安装目录，取决于它是否包含 `bin/elixir`（Windows 为 `bin\elixir.bat`），并且包含 `VERSION` 文件或 `lib/elixir/ebin/elixir.app` 之一。

名字的规则是：

- asdf 和 mise：目录名，例如 `1.16.2-otp-26`。
- 其他位置：`VERSION` 文件的内容；没有 `VERSION` 文件时，取 `lib/elixir/ebin/elixir.app` 中的版本。

名字必须以字母或数字开头，只能包含字母、数字、`.`、`_`、`+` 和 `-`，并且不能是 `latest`。不符合的安装会被跳过。

插件不会报告 vfox 自己的安装（位于 `.vfox` 或 `.version-fox` 下，或位于 `VFOX_HOME` 下），因为它们已经由 vfox 管理。同一路径只报告一次，同名的也只报告第一个找到的。列表按名字排序。

每一项后面的备注说明安装是在哪里找到的，例如 `installed by asdf`、`system Elixir` 或 `found on PATH`。备注只供参考，使用时请用名字。

## 手动链接

检测不到的安装，可以自己链接。安装目录是包含 `bin/`，并且包含 `VERSION` 或 `lib/elixir/ebin/elixir.app` 之一的目录：

```bash
vfox link elixir@1.16.2-otp-26 /path/to/elixir
vfox use -g elixir@1.16.2-otp-26
```

`vfox link` 的名字只能包含字母、数字、`.`、`_`、`+` 和 `-`，必须以字母或数字开头，且不能是 `latest`。vfox 在链接前会检查 `bin` 目录中是否有可执行的命令。
