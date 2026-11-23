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

The names are the lines of `builds.txt` with the leading `v` removed. `vfox search elixir hex` lists the ones with an OTP suffix:

| Name | Build |
| --- | --- |
| `1.16.2-otp-26` | Elixir 1.16.2 for Erlang/OTP 26 |
| `main-otp-26` | the `main` branch for Erlang/OTP 26 |

- A name with an OTP suffix says which Erlang/OTP the build is for, and `vfox install` prints it. Prefer these names.
- `builds.txt` also has names without a suffix, such as `main`, `master` and `1.16.2`. It does not say which Erlang/OTP they were built with, and one can refuse to run under another, so they are not listed. `vfox install` still installs one when you name it, and prints a warning once it has downloaded it.
- The `main` builds are updated. Installing the same name later can give a newer build.
- `latest` is not a hex.pm name. With `VFOX_ELIXIR_MIRROR=hex`, `latest` resolves to a release line such as `1.20-latest`, which has no pre-built build, so `vfox install` stops before the download. Name a build from `vfox search elixir hex` instead.

`vfox search elixir hex` prints the current list. `vfox search elixir` without the argument lists the releases, whatever `VFOX_ELIXIR_MIRROR` is set to, and prints nothing else. vfox keeps each search result by its argument, so the two lists do not show for each other.

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

`builds.txt` publishes a SHA-256 for most builds. The plugin reads it when the install starts, and vfox checks the downloaded zip against it before the zip is unpacked:

- vfox prints `Verifying checksum <sha256>...`. A zip that does not match stops the install.
- A build whose line in `builds.txt` has no SHA-256 is installed without the check. vfox prints `WARNING: Checksum is not provided, skip verify...` for it.
- If `builds.txt` cannot be read, the install stops before the download. Check the network connection, then install again.
