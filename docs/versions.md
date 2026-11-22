[中文](zh-CN/versions.md) | [English](versions.md)

# Versions and names

The part after `elixir@` is a version name. The name depends on where the build comes from:

| Source | Example name | What vfox installs |
| --- | --- | --- |
| Source, Linux and macOS | `1.16.2` | the source archive of the GitHub tag `v1.16.2`, compiled with `make` |
| Hex prebuilt, Linux and macOS (`VFOX_ELIXIR_MIRROR=hex`) | `1.16.2-otp-26`, `main-otp-26` | a prebuilt zip from builds.hex.pm |
| Official installer, Windows | `1.16.2-elixir-otp-26` | `elixir-otp-26.exe` from the GitHub release `v1.16.2` |

```bash
vfox search elixir                                         # names you can install
vfox install elixir@1.16.2                                 # source build, Linux and macOS
VFOX_ELIXIR_MIRROR=hex vfox install elixir@1.16.2-otp-26   # hex prebuilt, Linux and macOS
vfox install elixir@1.16.2-elixir-otp-26                   # Windows
vfox use -g elixir@1.16.2                                  # global default
vfox list elixir                                           # installed names
vfox uninstall elixir@1.16.2                               # remove one installed name
```

## The OTP suffix

Hex and Windows names end in `-otp-<N>` or `-elixir-otp-<N>`. `<N>` is the Erlang/OTP major version the build was made for. Install that Erlang/OTP first, see [erlang.md](erlang.md).

Source names have no suffix. They are compiled with the `erlc` that the plugin finds when you install, see [erlang.md](erlang.md#how-the-plugin-finds-erlc).

## The installed name

The name you type is the installed name. `vfox install elixir@1.16.2-otp-26` installs under `1.16.2-otp-26`, and `vfox list elixir` shows that name. The plugin does not rename it.

`vfox search` drops the `v` that builds.txt puts in front of a version: `v1.16.2-otp-26` is listed as `1.16.2-otp-26`. When the download is requested, a name that starts with a digit gets the `v` back (`1.16.2-otp-26` downloads `v1.16.2-otp-26.zip`).

## Searching

`vfox search elixir` lists the names for your platform:

- Linux and macOS: the names in `assets/versions.txt`.
- Windows: the names in `assets/versions_win.txt`.
- With `VFOX_ELIXIR_MIRROR=hex`: the names in [builds.txt](https://builds.hex.pm/builds/elixir/builds.txt).

The two files in this repository are refreshed by a scheduled workflow every week. vfox caches the result of `vfox search` for 12 hours by default (`cache.availableHookDuration`), so a version published a moment ago may not be listed yet.

## Using a version

`vfox use` chooses among the installed names:

- A complete installed name is used as it is: `vfox use -g elixir@1.16.2-otp-26`.
- A name without an OTP suffix, such as `1.16.2` or `main`, uses the installed name itself if it exists (a source build). Otherwise it uses the installed build with the highest OTP number: `1.16.2-otp-<N>` or `1.16.2-elixir-otp-<N>` for `1.16.2`, and `main-otp-<N>` for `main`. If `1.16.2-otp-25` and `1.16.2-otp-26` are both installed, `vfox use elixir@1.16.2` selects `1.16.2-otp-26`. If two installed builds have the same number, the name that sorts first is used.
- The match is on the whole version. `1.16` does not select `1.16.2-otp-26`.
- Anything else fails with `elixir@<version> is not installed`.

The scope is set with the flags of `vfox use`: `-g` (global), `-p` (project, writes `.vfox.toml`), or none (the current shell, which needs vfox's shell hook, see `vfox activate`).

`vfox exec` does not do this mapping. It looks for the name as it is installed, so `vfox exec elixir@1.16.2 -- elixir --version` installs the source release `1.16.2` instead of running `1.16.2-otp-26`. Give the complete name to `exec`, as in `vfox exec erlang@26.2.3 elixir@1.16.2-otp-26 -- elixir --version`: `elixir` also needs Erlang/OTP, and `exec` adds only Elixir's directory to `PATH`. Or select both with `vfox use` in a shell with the hook loaded, and run `elixir` directly. On Windows the program needs its extension, `elixir.bat`, see [troubleshooting.md](troubleshooting.md#vfox-exec-does-not-find-erl-or-elixir-on-windows).

## Pre-releases

Pre-releases use the same pattern: `1.20.0-rc.6` on Linux and macOS, and `1.19.0-rc.2-elixir-otp-28` on Windows.
