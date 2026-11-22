[中文](zh-CN/platforms.md) | [English](platforms.md)

# Platforms

The plugin runs on Linux, macOS and Windows. Each platform installs Elixir in its own way:

| Platform | Install method | Hex prebuilt (`VFOX_ELIXIR_MIRROR=hex`) |
| --- | --- | --- |
| Linux | source build with `make` | supported |
| macOS | source build with `make` | supported |
| Windows | official installer `.exe`, silent install | not supported, the install stops with an error |

| | Source (Linux, macOS) | Hex prebuilt (Linux, macOS) | Official installer (Windows) |
| --- | --- | --- | --- |
| Example name | `1.16.2` | `1.16.2-otp-26` | `1.16.2-elixir-otp-26` |
| Downloaded from | GitHub, `archive/refs/tags/v<version>.tar.gz` | builds.hex.pm, `<ref>.zip` | GitHub release `v<version>`, `elixir-otp-<N>.exe` |
| Build step | `make` | none | none, the installer runs silently |
| `erlc` needed to install | yes, see [erlang.md](erlang.md) | no | no |
| Erlang/OTP needed to run | yes | yes, the OTP major version must match `-otp-<N>` | yes, `erl` must be on `PATH` |
| Names listed by `vfox search` | `assets/versions.txt` | builds.txt | `assets/versions_win.txt` |

## Linux

You need:

- `make`. On Ubuntu and Debian it comes with `build-essential`.
- Erlang/OTP with `erl` and `erlc`, see [erlang.md](erlang.md).
- Access to github.com for the source archive.

```bash
vfox add erlang
vfox install erlang@26.2.3
vfox use -g erlang@26.2.3
vfox add elixir
vfox install elixir@1.16.2
vfox use -g elixir@1.16.2
```

`vfox use -g` takes effect in shells that load vfox, see `vfox activate` in the vfox documentation.

## macOS

You need `make`, which comes with the Xcode Command Line Tools (`xcode-select --install`), and Erlang/OTP. The commands are the same as on Linux. The build dependencies of Erlang/OTP are in [erlang.md](erlang.md).

This page was not tested on a Mac. macOS installs are covered by the E2E tests, see [e2e.md](e2e.md).

## Windows

You need:

- vfox 0.5.3 or later. `vfox link --detect` needs vfox 1.1.0 or later.
- Access to github.com. The installer is downloaded from there.
- Erlang/OTP, installed separately, see [erlang.md](erlang.md).

```powershell
vfox add erlang
vfox install erlang@26.2.3
vfox use -g erlang@26.2.3
vfox add elixir
vfox install elixir@1.16.2-elixir-otp-26
vfox use -g elixir@1.16.2-elixir-otp-26
```

What to know:

- The installer does not need Erlang/OTP to finish, but `elixir.bat` runs `erl`. Select Erlang/OTP with `vfox use -g` so that `erl` is on `PATH`.
- Version names are `<version>-elixir-otp-<N>`. Use `vfox search elixir` to see them. The list starts at `1.15.0-rc.2`. For older versions, the deprecated [Online Elixir Installer](https://github.com/elixir-lang/elixir-windows-setup/releases/tag/v2.4) is still available.
- The installer does not change `PATH`. The plugin adds `<path>\bin` through vfox's environment.
- Hex prebuilt packages are not available. `VFOX_ELIXIR_MIRROR=hex` and `vfox search elixir hex` are refused, see [mirror.md](mirror.md).

This page was not tested on Windows. The Windows install path is covered by the E2E tests, see [e2e.md](e2e.md).

## Erlang/OTP

Elixir needs Erlang/OTP on every platform. See [erlang.md](erlang.md) for the versions to pick and how the plugin finds it.
