[中文](troubleshooting.md) | [English](../troubleshooting.md)

# 问题排查

下面每个标题都是一条信息的开头。部分信息结尾还有细节，例如地址或错误码，这里用尖括号标出。报错原文保持英文。

## 插件输出的信息

### `Erlang/OTP was not found, and Elixir is compiled with it`

源码构建（Linux 或 macOS）没有找到 `erlc`：`PATH` 上没有，vfox 的 Erlang 缓存里没有，mise 的安装目录里也没有。用 `vfox install erlang@26.2.3` 安装 Erlang/OTP，再执行 `vfox use -g erlang@26.2.3`，或者把 `erlc` 放到 `PATH` 上。用 `which erlc` 检查。查找顺序见 [erlang.md](erlang.md)。

从 Hex 安装预编译包时不查找 `erlc`，见 [mirror.md](mirror.md)。

### `Elixir <version> was not found. Please confirm that the version exists`

源码构建需要 GitHub 上存在标签 `v<version>`。版本名要与 `vfox search elixir` 列出的一致，例如 `1.16.2`，而不是 `v1.16.2`。

只要 GitHub 的应答不是 `200 OK`，插件都会显示这条信息，包括速率限制和服务故障。如果版本确实在列表中，请检查网络，稍后再试。发布列表在 https://github.com/elixir-lang/elixir/releases 。

### `Failed to check https://github.com/elixir-lang/elixir/releases/tag/v<version>: <error>. Please check your network connection.`

插件无法访问 GitHub。见 [网络](#网络)。

### `Failed to fetch <list> from <url>: <error>. Please check your network connection.`

### `Failed to fetch <list> from <url>: HTTP status <code>.`

`<list>` 是 `the Elixir versions`、`the Windows Elixir versions` 或 `the hex.pm builds`。插件需要读取这些列表来回答 `vfox search elixir`，安装时也会再读一次。第一种形式表示没有收到应答，第二种表示服务器返回了错误。见 [网络](#网络)。

### `Elixir build failed with exit code <code>`

`make` 停止了。请阅读这条信息上方的输出。`vfox --debug install elixir@<version>` 会打印更多内容。常见原因：

- Erlang/OTP 与 Elixir 版本不匹配。请对照 [erlang.md](erlang.md) 中的表格。
- Erlang/OTP 安装不完整。检查 `erl` 和 `erlc` 是否都能运行，例如 `erl -noshell -eval 'io:format("~s~n", [erlang:system_info(otp_release)]), halt().'`。
- 缺少 `make`。Ubuntu 上它包含在 `build-essential` 中；macOS 上运行 `xcode-select --install` 安装。

如果失败后 vfox 仍然列出了这个版本，请先运行 `vfox uninstall elixir@<version>`，再重新安装。

### `Elixir installer failed with exit code <code>`

仅出现在 Windows。官方安装器运行了，但返回了错误。请阅读这条信息上方的输出。安装器以 `"<installer>" /S /D=<安装目录>` 的方式运行，运行之后会被删除。如果想自己查看安装器，可以从 `https://github.com/elixir-lang/elixir/releases/download/v<version>/elixir-otp-<N>.exe` 下载。

### `Downloading the installer failed: <url>: <error>`

仅出现在 Windows。无法从 github.com 下载安装器。见 [网络](#网络)。

### `On Windows Elixir comes from the official installer, so name the version it ships with ... does not match`

在 Windows 上，版本名必须以 `-elixir-otp-<N>` 结尾，例如 `1.16.2-elixir-otp-26`。只写 `1.16.2` 会在下载之前被拒绝。运行 `vfox search elixir` 查看可用的名字。

### `VFOX_ELIXIR_MIRROR=hex is not available on Windows`

Hex 预编译包只用于 Linux 和 macOS。请取消设置 `VFOX_ELIXIR_MIRROR`，改用官方安装器的名字，例如 `1.16.2-elixir-otp-26`。见 [平台](platforms.md#windows)。

### `You must provide a version number for Elixir, eg: vfox install elixir@1.16.2`

安装命令没有给出版本。请在 `@` 后面写上版本名。

## vfox 输出的信息

### `elixir@<version> is not installed`

`vfox use` 和 `vfox uninstall` 只认识已安装的名字。运行 `vfox list elixir`，写出完整的名字，例如 `1.16.2-otp-26`。不完整的版本不会匹配：`1.16` 不会选中 `1.16.2-otp-26`。见 [版本与命名](versions.md#使用版本)。

### `elixir@<version> is already installed`

vfox 不会重新下载已经安装的名字。要重新安装，请先运行 `vfox uninstall elixir@<version>`。

### `plugin named elixir already exists`

你已经添加过 elixir 插件，又执行了 `vfox add elixir`。见 [从源码安装](install-from-source.md#已经添加过-elixir)。

### `No new elixir installations found.`

`vfox link --detect elixir` 没有找到可以链接的安装。插件会跳过 vfox 自己管理的安装，以及已经链接或已用同名安装的情况。见 [使用本机已有的 Elixir](link.md)。

### `Use the -y flag to link what was found in non-interactive environments`

`vfox link --detect` 在链接之前会询问。在没有终端的环境（例如 CI）中，请加上 `-y`：`vfox link --detect -y elixir`。

### `vfox link` 不接受 `--detect`

`vfox link --detect` 需要 vfox 1.1.0 或更高版本。用 `vfox --version` 检查。

## 其他问题

### `elixir: command not found`，或者运行的是错误的版本

`vfox use -g` 设置的是新 Shell 的默认版本，但当前 Shell 需要加载一次 vfox 的钩子才能生效。Bash 中执行 `eval "$(vfox activate bash)"`，PowerShell 中执行 `Invoke-Expression "$(vfox activate pwsh)"`。用 `vfox current elixir` 查看当前选中的版本。

### 找不到 `erl`，或者 Windows 上 `elixir.bat` 中途停止

说明没有选中 Erlang/OTP。运行 `vfox use -g erlang@26.2.3`，再加载一次钩子，然后用 [erlang.md](erlang.md#windows) 中的命令检查。

### `vfox exec` 在 Windows 上找不到 `erl` 或 `elixir`

vfox 1.1.0 只按写出的名字在 SDK 的 PATH 中查找命令，不会尝试 PATHEXT 中的扩展名。因此即使 `erl.exe` 已经安装，`vfox exec erlang@26.2.3 -- erl` 也会失败，报 `command not found: erl`。请带上扩展名：`vfox exec erlang@26.2.3 -- erl.exe`，以及 `vfox exec elixir@1.16.2-elixir-otp-26 -- elixir.bat`。在已加载钩子（`vfox activate pwsh`）的 Shell 中，`erl` 和 `elixir` 无需扩展名即可运行。

### 安装预编译包后运行时出现错误

名字中的 OTP 编号必须与运行 Elixir 的 Erlang/OTP 一致。`1.16.2-otp-26` 需要 Erlang/OTP 26。用 [erlang.md](erlang.md#windows) 中的命令检查版本。

### 路径含空格时失败

Elixir 的安装在所有平台上都能处理 vfox 主目录中的空格，见 [变更记录](changes.md)。但 Erlang/OTP 的源码构建不能：它的 `configure` 步骤不会给路径加引号。在 Linux 和 macOS 上，从源码构建 Erlang/OTP 时请让 vfox 主目录的路径不含空格。如果 Elixir 的安装在路径含空格时仍然失败，请连同输出一起报告，见下文。

### `vfox link --detect` 找不到 Elixir 安装

- 目录中必须有 `bin/elixir`（Windows 上为 `bin\elixir.bat`），并且有 `VERSION` 文件或 `lib/elixir/ebin/elixir.app` 之一。
- 位于 `.vfox`、`.version-fox` 下，或位于 `VFOX_HOME` 下的安装永远不会被列出，因为它们由 vfox 管理。
- 手动链接：`vfox link elixir@<名字> <路径>`，见 [使用本机已有的 Elixir](link.md#手动链接)。

### 版本列表过时

`vfox search` 会保存 12 小时的结果。可以等待，或者用 `vfox config cache.availableHookDuration` 缩短缓存时间。

## 网络

插件从 `fastly.jsdelivr.net`（Linux、macOS 和 Windows）读取版本列表，从 `builds.hex.pm`（Hex）读取预编译包列表。它会在 github.com 上检查源码发行版是否存在，并从 github.com 下载源码包或 Windows 安装器。

如果其中某个站点被阻断或速度很慢，可以设置 vfox 的代理，它对 vfox 的所有请求都生效：

```bash
vfox config proxy.enable true
vfox config proxy.url http://127.0.0.1:7890
```

## 报告问题

请在 [version-fox/vfox-elixir](https://github.com/version-fox/vfox-elixir/issues) 上提交 issue，并附上 `vfox --version` 的输出、操作系统和 CPU、你运行的命令，以及它打印的全部内容。`vfox --debug <命令>` 会打印更多内容。
