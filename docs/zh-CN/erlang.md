[中文](erlang.md) | [English](../erlang.md)

# Erlang/OTP

Elixir 运行在 Erlang 虚拟机上，所以必须先安装 Erlang/OTP。插件在 `metadata.lua` 中声明了对 `erlang` 插件的依赖，但 vfox 不会安装依赖，请自行安装 Erlang/OTP。

有两个步骤需要它：

- 源码构建（Linux 和 macOS）用某个 Erlang/OTP 安装中的 `erlc` 编译 Elixir。
- 在任何平台上运行 `elixir`、`iex` 或 `mix` 都需要 `erl`。

## 用 vfox-erlang 安装 Erlang/OTP

[vfox-erlang](https://github.com/version-fox/vfox-erlang) 从源码安装 Erlang/OTP：

```bash
vfox add erlang
vfox install erlang@26.2.3
vfox use -g erlang@26.2.3
```

编译 Erlang/OTP 前需要先装一些系统包。下面是 E2E 工作流在 Ubuntu 24.04 上安装的包：

```bash
sudo apt-get update -y
sudo apt-get install -y build-essential autoconf m4 libncurses-dev libssl-dev libssh-dev unixodbc-dev xsltproc fop libxml2-utils openjdk-11-jdk
```

在 Linux 上，工作流没有安装 wxWidgets：Erlang/OTP 不带它也能编译，只是不会构建其中的 wx 应用。macOS 上，工作流安装的是：

```bash
brew install autoconf libxslt fop wxwidgets openssl
```

不同发行版的包名不同，请以 vfox-erlang 的文档为准。

在 Linux 和 macOS 上，请让 vfox 主目录的路径不含空格。Erlang/OTP 的 `configure` 步骤不会给路径加引号，路径中有空格时源码构建会失败。Windows 上的官方安装器不做编译，因此上面 `configure` 的规则不适用于 Windows。

## 选择兼容的版本

Elixir 只支持部分 Erlang/OTP 版本。以下是 Elixir 1.16.2 的官方兼容表（2026-11-21 核对）：

| Elixir | 支持的 Erlang/OTP |
| --- | --- |
| 1.16 | 24 到 26 |
| 1.15 | 24 到 26 |
| 1.14 | 23 到 25，从 v1.14.5 起支持 26 |

使用 Elixir `1.16.2` 时，请选择 Erlang/OTP `26.2.3`，本文档的示例都是这个组合。该表没有列出 Elixir 1.16 与 OTP 27 或更高版本的组合。其他版本请查看对应版本的表：`https://hexdocs.pm/elixir/<版本>/compatibility-and-deprecations.html`，例如 [1.16.2 的页面](https://hexdocs.pm/elixir/1.16.2/compatibility-and-deprecations.html#between-elixir-and-erlang-otp)。

Elixir 名字中的 OTP 编号（`-otp-26`、`-elixir-otp-26`）必须与你运行的 Erlang/OTP 一致。

## 插件如何找到 erlc

源码构建需要一个 `erlc`。插件按以下顺序查找，使用第一个找到的：

1. `PATH` 上的 `erlc`。这包括 `vfox use -g` 放到 `PATH` 上的 Erlang/OTP，以及 `PATH` 上其他的 `erlc`。
2. vfox 自己的 Erlang 缓存：`<VFOX_HOME>/cache/erlang` 下的 `erlc`，最多查找六层目录。`vfox install erlang@26.2.3` 把 Erlang/OTP 装在这里。源码构建的 `erlc` 在 `release/bin` 中，优先使用；然后是 `bin` 和 `lib/erlang/bin`，预编译安装把它放在那里。OTP 的 `bootstrap` 目录从不使用，因为它的 Erlang/OTP 没有 `make` 模块。`<VFOX_HOME>` 是 vfox 的主目录。
3. mise 的 Erlang/OTP 安装：`$MISE_DATA_DIR/installs/erlang`；未设置 `MISE_DATA_DIR` 时为 `~/.local/share/mise/installs/erlang`，最多查找五层目录。

找到的 `erlc` 所在目录会在运行 `make` 时放到 `PATH` 最前面。如果都找不到，安装会报错停止，见 [troubleshooting.md](troubleshooting.md)。

Hex 预编译包的安装不查找 `erlc`，但运行 Elixir 时仍需要 `erl`。

## Windows

Windows 官方安装器不需要 Erlang/OTP 也能完成安装。但运行 Elixir 需要：`elixir.bat` 会调用 `erl`。使用 Elixir 之前，请先选择 Erlang/OTP：

```powershell
vfox use -g erlang@26.2.3
Invoke-Expression "$(vfox activate pwsh)"
& erl.exe -eval 'erlang:display({otp_release, erlang:system_info(otp_release)}), halt().' -noshell
```

最后一条命令会输出 Erlang/OTP 的主版本号。
