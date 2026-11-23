[中文](zh-CN/troubleshooting.md) | [English](troubleshooting.md)

# Troubleshooting

Each heading below is the start of a message. Some messages end with a detail, such as a URL or an error code, shown here in angle brackets.

## Messages from the plugin

### `Erlang/OTP was not found, and Elixir is compiled with it`

A source build (Linux or macOS) found no `erlc`: not on `PATH`, not in vfox's Erlang cache, and not in mise's installs. Install Erlang/OTP with `vfox install erlang@26.2.3`, then `vfox use -g erlang@26.2.3`, or put `erlc` on `PATH`. Check with `which erlc`. The search order is in [erlang.md](erlang.md).

A prebuilt install from hex does not look for `erlc`, see [mirror.md](mirror.md).

### `Elixir <version> was not found. Please confirm that the version exists`

A source build needs a GitHub release tag `v<version>`. Write the version as `vfox search elixir` lists it, such as `1.16.2`, not `v1.16.2`.

The plugin shows this message for any answer from GitHub other than `200 OK`, including rate limits and outages. If the version is listed and you are sure it exists, check your network and try again later. The release list is at https://github.com/elixir-lang/elixir/releases.

### `Failed to check https://github.com/elixir-lang/elixir/releases/tag/v<version>: <error>. Please check your network connection.`

The plugin could not reach GitHub. See [Network](#network).

### `Failed to fetch <list> from <url>: <error>. Please check your network connection.`

No answer came from the server. See [Network](#network).

### `Failed to fetch <list> from <url>: HTTP status <code>.`

`<list>` is `the Elixir versions`, `the Windows Elixir versions`, `the hex.pm builds` or `the hex.pm builds index`. The plugin reads these lists to answer `vfox search elixir`, and it reads them again for an install. `the hex.pm builds index` is `builds.txt`, which an install with `VFOX_ELIXIR_MIRROR=hex` reads for the checksum of the zip. The first form means no answer came, the second means the server answered with an error. See [Network](#network).

### `Failed to fetch <list> from <url>: the response is not a list of versions. Check your network connection and proxy settings.`

The server answered with status 200, but the body is an error page, an empty body, or plain text with no version names, such as `Error code: 404`. The plugin lists and caches nothing from such an answer, so the search or the install stops with this message. Check the proxy settings, see [Network](#network), and run the command again.

### `Elixir build failed: make stopped with an error`

`make` stopped. Read the output above this message. `vfox --debug install elixir@<version>` prints more. Common causes:

- Erlang/OTP does not match the Elixir version. Check the table in [erlang.md](erlang.md).
- The Erlang/OTP install is incomplete. Check that `erl` and `erlc` both run, for example `erl -noshell -eval 'io:format("~s~n", [erlang:system_info(otp_release)]), halt().'`.
- `make` is missing. On Ubuntu it comes with `build-essential`. On macOS it comes with `xcode-select --install`.

If vfox still lists the version after the failure, run `vfox uninstall elixir@<version>` before you install it again.

### `Elixir's source build cannot run in <path>: Elixir's Makefile does not quote its directory, ...`

A source build on Linux and macOS stops before `make` when the vfox home (`VFOX_HOME`) has a space, a quote or another character that the shell reads. The message names the path. Keep those characters out of the vfox home and install again. See [A path with spaces or other shell characters fails](#a-path-with-spaces-or-other-shell-characters-fails).

### `Elixir installer failed: the installer stopped with an error`

Windows only. The official installer ran and returned an error. Read the output above this message. The installer is run as `"<installer>" /S /D=<install directory>`, and it is removed after it runs. To look at it yourself, download `https://github.com/elixir-lang/elixir/releases/download/v<version>/elixir-otp-<N>.exe`.

### `Downloading the installer failed: <url>: <error>`

Windows only. The installer could not be downloaded from github.com. See [Network](#network).

### `On Windows Elixir comes from the official installer, so name the version it ships with ... does not match`

On Windows a version name must end in `-elixir-otp-<N>`, for example `1.16.2-elixir-otp-26`. `1.16.2` alone is refused before anything is downloaded. Run `vfox search elixir` to see the names.

### `The hex.pm builds (VFOX_ELIXIR_MIRROR=hex, or vfox search elixir hex) are not available on Windows`

The hex.pm builds, which `VFOX_ELIXIR_MIRROR=hex` and `vfox search elixir hex` use, are for Linux and macOS. Install a name from the official installer, such as `1.16.2-elixir-otp-26`. See [platforms.md](platforms.md#windows).

### `Elixir <version> has no pre-built build on hex.pm: it is a release line, and latest resolves to one.`

With `VFOX_ELIXIR_MIRROR=hex`, `latest` resolves to a release line such as `1.20-latest`, and hex.pm has no build for a release line. `vfox install` stops before the download. Name a build that `vfox search elixir hex` lists, such as `1.16.2-otp-26`, or unset `VFOX_ELIXIR_MIRROR` to build from source. See [mirror.md](mirror.md#names).

### `Warning: this name has no -otp-N suffix, so hex.pm does not say which Erlang/OTP the build is for. ...`

Printed by `vfox install` with `VFOX_ELIXIR_MIRROR=hex`, after the build is downloaded, for a name such as `main` or `1.16.2`. The install goes on. A name that hex.pm does not have fails at the download, and gets no warning. For a name with a suffix, `vfox install` prints `This build needs Erlang/OTP <N>.` instead. If `elixir` then refuses to run, install a name with `-otp-N`, see [mirror.md](mirror.md#names).

### `Checksum error, file: <path>`

With `VFOX_ELIXIR_MIRROR=hex`, the zip that was downloaded does not match the SHA-256 that `builds.txt` publishes for the build. vfox prints `Verifying checksum <sha256>...`, then this message, and it stops before the zip is unpacked. The install ends with `checksum error` and `failed to install elixir`.

Run `vfox install` again. Each install reads `builds.txt` anew, so a build that hex.pm replaced between that read and the download is checked against its new SHA-256. If the error stays, the zip and the index on builds.hex.pm do not agree, or something on the network path changes the download. Run `vfox --debug install elixir@<version>` and report it, see [Reporting a problem](#reporting-a-problem).

### `You must provide a version number for Elixir, eg: vfox install elixir@1.16.2`

The install command had no version. Write the name after `@`.

## Messages from vfox

### `elixir@<version> is not installed`

`vfox use` and `vfox uninstall` only know installed names. Run `vfox list elixir` and write the whole name, such as `1.16.2-otp-26`. A partial version does not match: `1.16` does not select `1.16.2-otp-26`. See [versions.md](versions.md#using-a-version).

### `elixir@<version> is already installed`

vfox does not download an installed name again. To reinstall, run `vfox uninstall elixir@<version>` first.

### `plugin named elixir already exists`

`vfox add elixir` was run when the plugin is already added. See [install-from-source.md](install-from-source.md#when-elixir-is-already-added).

### `No new elixir installations found.`

`vfox link --detect elixir` found nothing it can link. The plugin skips installs that are managed by vfox, and installs that are already linked or already installed under the same name. See [link.md](link.md).

### `Use the -y flag to link what was found in non-interactive environments`

`vfox link --detect` asks before it links. Without a terminal, such as in CI, add `-y`: `vfox link --detect -y elixir`.

### `vfox link` rejects `--detect`

`vfox link --detect` needs vfox 1.1.0 or later. Check with `vfox --version`.

## Other problems

### `elixir: command not found`, or the wrong version runs

`vfox use -g` sets the default for new shells, but the current shell needs vfox's hook to pick up changes. Load the hook once: `eval "$(vfox activate bash)"` in Bash, `Invoke-Expression "$(vfox activate pwsh)"` in PowerShell. Check the selected version with `vfox current elixir`.

### `erl` is not found, or `elixir.bat` stops on Windows

Erlang/OTP is not selected. Run `vfox use -g erlang@26.2.3`, load the hook again, and check with the command in [erlang.md](erlang.md#windows).

### `vfox exec` does not find `erl` or `elixir` on Windows

vfox 1.1.0 finds a command in the PATH of the SDKs only by the name as typed, and it does not try the extensions of PATHEXT there. So `vfox exec erlang@26.2.3 -- erl` fails with `command not found: erl`, although `erl.exe` is installed. Give the extension: `vfox exec erlang@26.2.3 -- erl.exe`, and `vfox exec elixir@1.16.2-elixir-otp-26 -- elixir.bat`. In a shell with the hook loaded (`vfox activate pwsh`), `erl` and `elixir` run without it.

### `exec: erl: not found` when Elixir runs

`elixir` starts `erl`, which must be on `PATH`. `vfox exec elixir@<version> -- elixir` adds only Elixir's directory to `PATH`, so it fails when Erlang/OTP is not already on `PATH`. Name Erlang/OTP in the same command: `vfox exec erlang@26.2.3 elixir@1.16.2 -- elixir --version`. A prebuilt install from hex (see [mirror.md](mirror.md)) needs the same, because its zip does not contain Erlang/OTP. Or select both with `vfox use` in a shell with the hook loaded, and run `elixir` directly.

### Runtime errors after installing a prebuilt build

The OTP number in the name must match the Erlang/OTP that runs Elixir. `1.16.2-otp-26` needs Erlang/OTP 26. Check the version with `erl -noshell -eval 'io:format("~s~n", [erlang:system_info(otp_release)]), halt().'`, which prints `26`.

### A path with spaces or other shell characters fails

A source build of Elixir on Linux and macOS stops before `make` when the vfox home (`VFOX_HOME`) has a space, a quote or another character that the shell reads, such as `$`, `;`, `&`, `(` or `*`. The error names the path. Elixir's Makefile puts the directory into a command without quotes, so `make` cannot build there. Keep those characters out of the vfox home and install again. A prebuilt build (`VFOX_ELIXIR_MIRROR=hex`) runs no `make`, so this does not apply to it. Erlang/OTP's source build has the same limit, because its `configure` step does not quote paths: on Linux and macOS, keep spaces out of the vfox home when you build Erlang/OTP from source, see [erlang.md](erlang.md).

### `vfox link --detect` does not find the Elixir installation

- The directory must contain an executable `bin/elixir` (on Windows `bin\elixir.bat`) and either a `VERSION` file or `lib/elixir/ebin/elixir.app`. A launcher without the execute bit is skipped; `chmod +x bin/elixir` makes the install a candidate again.
- Installs under `.vfox`, `.version-fox`, or under `VFOX_HOME` are never listed, because vfox manages them.
- Link it by hand: `vfox link elixir@<name> <path>`, see [link.md](link.md#linking-by-hand).

### The version list is out of date

`vfox search` keeps each result for 12 hours, in `<VFOX_HOME>/plugin/elixir/.available.cache`. Each argument has its own entry: no argument for the releases, `hex` for the hex.pm builds. To refresh it, delete that file. To turn the cache off for all plugins, run `vfox config cache.availableHookDuration 0s`.

## Network

The plugin reads the version list from `fastly.jsdelivr.net` (Linux, macOS and Windows) and from `builds.hex.pm` (hex). An install with `VFOX_ELIXIR_MIRROR=hex` also reads `builds.txt` from `builds.hex.pm`, for the checksum of the zip. It checks each source release on github.com, and downloads the source archive or the Windows installer from github.com.

If one of these hosts is blocked or slow, set vfox's proxy, which covers all of vfox's requests:

```bash
vfox config proxy.enable true
vfox config proxy.url http://127.0.0.1:7890
```

## Reporting a problem

Open an issue at [version-fox/vfox-elixir](https://github.com/version-fox/vfox-elixir/issues) with the output of `vfox --version`, the operating system and CPU, the command you ran, and everything it printed. `vfox --debug <command>` prints more.
