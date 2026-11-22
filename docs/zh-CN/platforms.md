[中文](platforms.md) | [English](../platforms.md)

# 平台

插件可以在 Linux、macOS 和 Windows 上运行。每个平台的安装方式不同：

| 平台 | 安装方式 | Hex 预编译包（`VFOX_ELIXIR_MIRROR=hex`） |
| --- | --- | --- |
| Linux | 用 `make` 从源码构建 | 支持 |
| macOS | 用 `make` 从源码构建 | 支持 |
| Windows | 官方安装器 `.exe`，静默安装 | 不支持，安装会直接报错 |

| | 源码（Linux、macOS） | Hex 预编译包（Linux、macOS） | 官方安装器（Windows） |
| --- | --- | --- | --- |
| 版本名示例 | `1.16.2` | `1.16.2-otp-26` | `1.16.2-elixir-otp-26` |
| 下载来源 | GitHub，`archive/refs/tags/v<版本>.tar.gz` | builds.hex.pm，`<ref>.zip` | GitHub 发行版 `v<版本>`，`elixir-otp-<N>.exe` |
| 构建步骤 | `make` | 无 | 无，安装器静默运行 |
| 安装时需要 `erlc` | 需要，见 [erlang.md](erlang.md) | 不需要 | 不需要 |
| 运行时需要 Erlang/OTP | 需要 | 需要，OTP 主版本必须与 `-otp-<N>` 一致 | 需要，`erl` 必须在 `PATH` 上 |
| `vfox search` 列出的来源 | `assets/versions.txt` | builds.txt | `assets/versions_win.txt` |

## Linux

需要：

- `make`。Ubuntu 和 Debian 上它包含在 `build-essential` 中。
- 带有 `erl` 和 `erlc` 的 Erlang/OTP，见 [erlang.md](erlang.md)。
- 能访问 github.com，以下载源码包。

```bash
vfox add erlang
vfox install erlang@26.2.3
vfox use -g erlang@26.2.3
vfox add elixir
vfox install elixir@1.16.2
vfox use -g elixir@1.16.2
```

`vfox use -g` 对已挂载 vfox 的 Shell 生效，挂载方法见 vfox 文档中的 `vfox activate`。

## macOS

需要 `make`（由 Xcode Command Line Tools 提供，运行 `xcode-select --install` 安装）和 Erlang/OTP。命令与 Linux 相同。Erlang/OTP 的构建依赖见 [erlang.md](erlang.md)。

本页没有在 Mac 上实际测试。macOS 上的安装由 E2E 测试覆盖，见 [e2e.md](e2e.md)。

## Windows

需要：

- vfox 0.5.3 或更高版本。`vfox link --detect` 需要 vfox 1.1.0 或更高版本。
- 能访问 github.com，安装器从那里下载。
- 单独安装的 Erlang/OTP，见 [erlang.md](erlang.md)。

```powershell
vfox add erlang
vfox install erlang@26.2.3
vfox use -g erlang@26.2.3
vfox add elixir
vfox install elixir@1.16.2-elixir-otp-26
vfox use -g elixir@1.16.2-elixir-otp-26
```

注意事项：

- 安装器不需要 Erlang/OTP 也能完成，但 `elixir.bat` 会调用 `erl`。使用 Elixir 之前，请用 `vfox use -g` 选择 Erlang/OTP，让 `erl` 在 `PATH` 上。
- 版本名为 `<版本>-elixir-otp-<N>`，用 `vfox search elixir` 查看。列表从 `1.15.0-rc.2` 开始。更早的版本可以使用已弃用的 [Online Elixir Installer](https://github.com/elixir-lang/elixir-windows-setup/releases/tag/v2.4)。
- 安装器不会修改 `PATH`。插件通过 vfox 的环境变量加入 `<路径>\bin`。
- 没有 Hex 预编译包。`VFOX_ELIXIR_MIRROR=hex` 和 `vfox search elixir hex` 都会被拒绝，见 [mirror.md](mirror.md)。

本页没有在 Windows 上实际测试。Windows 的安装流程由 E2E 测试覆盖，见 [e2e.md](e2e.md)。

## Erlang/OTP

所有平台都需要 Erlang/OTP。要选择的版本，以及插件如何找到它，见 [erlang.md](erlang.md)。
