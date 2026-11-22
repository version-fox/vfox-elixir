[中文](zh-CN/mirror.md) | [English](mirror.md)

# Hex prebuilt packages

Setting `VFOX_ELIXIR_MIRROR=hex` makes the plugin install prebuilt Elixir zips from [builds.hex.pm](https://builds.hex.pm/builds/elixir/builds.txt) instead of compiling the source. The variable is read by `vfox install`, and it has an effect only when its value is exactly `hex`. To list the builds, search with the argument `hex`: `vfox search elixir hex`.

```bash
vfox search elixir hex
VFOX_ELIXIR_MIRROR=hex vfox install elixir@1.16.2-otp-26
vfox use -g elixir@1.16.2-otp-26
```

`vfox use` does not need the variable. It selects from the installed names.

## Names

The names are the lines of `builds.txt` with the leading `v` removed. They include:

| Name | Build |
| --- | --- |
| `1.16.2-otp-26` | Elixir 1.16.2 for Erlang/OTP 26 |
| `main-otp-26` | the `main` branch for Erlang/OTP 26 |
| `main`, `master` | the `main` and `master` branches, without an OTP suffix |
| `1.16.2` | Elixir 1.16.2, without an OTP suffix |

- Names with an OTP suffix say which Erlang/OTP the build is for. Prefer them.
- Names without a suffix are listed too, but `builds.txt` does not say which Erlang/OTP they were built with.
- The `main` and `master` names are updated. Installing the same name later can give a newer build.

`vfox search elixir hex` prints the current list. `vfox search elixir` without the argument lists the releases, whatever `VFOX_ELIXIR_MIRROR` is set to. vfox keeps each search result by its argument, so the two lists do not show for each other.

## Compared with a source build

| | Source build | Hex prebuilt |
| --- | --- | --- |
| Platforms | Linux, macOS, and Windows (installer) | Linux and macOS |
| Compiles | yes, with `make` | no |
| Needs `erlc` to install | yes | no |
| Needs Erlang/OTP to run | yes | yes, and the OTP major version must match the suffix |
| Example name | `1.16.2` | `1.16.2-otp-26` |

## Windows

Hex prebuilt packages are not available on Windows. With `VFOX_ELIXIR_MIRROR=hex`, `vfox install` or `vfox search elixir hex` stops with an error that the builds are not available on Windows. Nothing is downloaded. On Windows, use the official installer names, such as `1.16.2-elixir-otp-26`, see [platforms.md](platforms.md#windows).

## Checksums

The plugin does not check the downloaded zip against the `sha256` value in `builds.txt`.
