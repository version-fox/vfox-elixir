[中文](mirror.md) | [English](../mirror.md)

# Hex 预编译包

设置 `VFOX_ELIXIR_MIRROR=hex` 后，插件会从 [builds.hex.pm](https://builds.hex.pm/builds/elixir/builds.txt) 安装预编译的 Elixir zip，而不是编译源码。`vfox install` 会读取这个变量，且只有值正好是 `hex` 时才生效。要列出这些构建，请用参数 `hex` 搜索：`vfox search elixir hex`。

```bash
vfox search elixir hex
VFOX_ELIXIR_MIRROR=hex vfox install elixir@1.16.2-otp-26
vfox use -g elixir@1.16.2-otp-26
```

`vfox use` 不需要这个变量，它从已安装的名字中选择。

## 名字

名字是 `builds.txt` 中各行去掉开头 `v` 之后的内容。`vfox search elixir hex` 只列出带 OTP 后缀的名字：

| 名字 | 构建内容 |
| --- | --- |
| `1.16.2-otp-26` | 面向 Erlang/OTP 26 的 Elixir 1.16.2 |
| `main-otp-26` | 面向 Erlang/OTP 26 的 `main` 分支 |

- 带 OTP 后缀的名字写明了构建面向的 Erlang/OTP 版本，`vfox install` 会打印它。优先使用它们。
- `builds.txt` 还有不带后缀的名字，例如 `main`、`master` 和 `1.16.2`。`builds.txt` 没有写明它们是用哪个 Erlang/OTP 构建的，其中一些可能拒绝在另一个 Erlang/OTP 下运行，所以不会列出。你指定它们时，`vfox install` 仍会安装，并先打印警告。
- `main` 构建会更新。过一段时间再安装同一个名字，可能得到更新的构建。
- `latest` 不是 hex.pm 的名字。设置 `VFOX_ELIXIR_MIRROR=hex` 后，`latest` 会解析为 `1.20-latest` 这样的发布线，它没有预编译构建，所以 `vfox install` 会在下载前停止。请改用 `vfox search elixir hex` 列出的名字。

`vfox search elixir hex` 会输出当前的列表。`vfox search elixir` 不带参数时列出源码版本，与 `VFOX_ELIXIR_MIRROR` 的设置无关。设置了 `VFOX_ELIXIR_MIRROR=hex` 时，它在读取列表（而不是读取缓存）时会在标准错误输出一条提示，指向 `vfox search elixir hex`。vfox 按搜索参数分别缓存结果，因此两种列表不会互相显示。

## 与源码构建的区别

| | 源码构建 | Hex 预编译包 |
| --- | --- | --- |
| 平台 | Linux、macOS，以及 Windows（安装器） | Linux 和 macOS |
| 是否编译 | 是，用 `make` | 否 |
| 安装时需要 `erlc` | 需要 | 不需要 |
| 运行时需要 Erlang/OTP | 需要 | 需要，且 OTP 主版本必须与后缀一致 |
| 名字示例 | `1.16.2` | `1.16.2-otp-26` |

## Windows

Windows 没有 Hex 预编译包。设置 `VFOX_ELIXIR_MIRROR=hex` 后，`vfox install`，或者 `vfox search elixir hex`，会直接报错，提示这些构建在 Windows 上不可用，并且不会下载任何内容。在 Windows 上请使用官方安装器的名字，例如 `1.16.2-elixir-otp-26`，见 [platforms.md](platforms.md#windows)。

## 校验和

插件不会用 `builds.txt` 中的 `sha256` 校验下载的 zip。
