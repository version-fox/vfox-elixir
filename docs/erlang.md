[中文](zh-CN/erlang.md) | [English](erlang.md)

# Erlang/OTP

Elixir runs on the Erlang virtual machine, so Erlang/OTP must be installed. The plugin declares a dependency on the `erlang` plugin in `metadata.lua`, but vfox does not install dependencies, so install Erlang/OTP yourself.

Two steps need it:

- A source build (Linux and macOS) compiles Elixir with the `erlc` of an Erlang/OTP install.
- Running `elixir`, `iex` or `mix` on any platform needs `erl`.

## Install Erlang/OTP with vfox-erlang

[vfox-erlang](https://github.com/version-fox/vfox-erlang) installs Erlang/OTP from source:

```bash
vfox add erlang
vfox install erlang@26.2.3
vfox use -g erlang@26.2.3
```

Building Erlang/OTP needs system packages first. On Ubuntu 24.04 the E2E workflow installs:

```bash
sudo apt-get update -y
sudo apt-get install -y build-essential autoconf m4 libncurses-dev libssl-dev libssh-dev unixodbc-dev xsltproc fop libxml2-utils openjdk-11-jdk
```

On Linux the workflow leaves out wxWidgets: Erlang/OTP builds without it, and its wx applications are not built. On macOS the workflow installs:

```bash
brew install autoconf libxslt fop wxwidgets openssl
```

The package names differ between distributions, so check the vfox-erlang documentation for your system.

On Linux and macOS, keep spaces out of the vfox home. Erlang/OTP's `configure` step does not quote paths, so a space in the path makes its source build fail. On Windows the official installer does not build anything, so the `configure` rule does not apply there.

## Choose a compatible version

Elixir supports only some Erlang/OTP versions. The official table for Elixir 1.16.2 (checked on 2026-11-21) lists:

| Elixir | Supported Erlang/OTP |
| --- | --- |
| 1.16 | 24 to 26 |
| 1.15 | 24 to 26 |
| 1.14 | 23 to 25, and 26 from v1.14.5 |

For `1.16.2`, use Erlang/OTP `26.2.3`, which the examples in this documentation use. The table has no entry for OTP 27 or later with Elixir 1.16. For other versions, read the table for that version: `https://hexdocs.pm/elixir/<version>/compatibility-and-deprecations.html`, for example [the 1.16.2 page](https://hexdocs.pm/elixir/1.16.2/compatibility-and-deprecations.html#between-elixir-and-erlang-otp).

The OTP number in an Elixir name (`-otp-26`, `-elixir-otp-26`) must match the Erlang/OTP you run.

## How the plugin finds erlc

A source build needs an `erlc`. The plugin looks in this order and uses the first match:

1. `erlc` on `PATH`. This includes the Erlang/OTP that `vfox use -g` put on `PATH`, and any other `erlc` on `PATH`.
2. vfox's own Erlang cache: `erlc` inside `<VFOX_HOME>/cache/erlang`, searched up to six directories deep. `vfox install erlang@26.2.3` stores Erlang/OTP there. A source build keeps its `erlc` in `release/bin`, which is taken first; then `bin` and `lib/erlang/bin`, where a prebuilt install keeps it. OTP's `bootstrap` directory is never used, because its Erlang/OTP has no `make` module. `<VFOX_HOME>` is vfox's home directory.
3. mise's Erlang/OTP installs: `$MISE_DATA_DIR/installs/erlang`, or `~/.local/share/mise/installs/erlang` when `MISE_DATA_DIR` is not set, searched up to five directories deep.

The directory of the `erlc` that was found is put first on `PATH` while `make` runs. If none is found, the install stops with an error, see [troubleshooting.md](troubleshooting.md).

A hex prebuilt install does not look for `erlc`, but it still needs `erl` when you run Elixir.

## Windows

The official Windows installer does not need Erlang/OTP to finish. Running Elixir does: `elixir.bat` calls `erl`. Select Erlang/OTP before you use Elixir:

```powershell
vfox use -g erlang@26.2.3
Invoke-Expression "$(vfox activate pwsh)"
& erl.exe -eval 'erlang:display({otp_release, erlang:system_info(otp_release)}), halt().' -noshell
```

The last command prints the Erlang/OTP major version.
