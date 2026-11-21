[中文](zh-CN/development.md) | [English](development.md)

# Development

## Layout

```
metadata.lua                    plugin name, version, dependency, notes
hooks/available.lua             vfox search
hooks/pre_install.lua           vfox install: the version name and the download URL
hooks/post_install.lua          vfox install: the source build (Linux, macOS) or the installer (Windows)
hooks/pre_use.lua               vfox use: maps what was typed to an installed name
hooks/env_keys.lua              PATH for an installed version
hooks/detect.lua                vfox link --detect: Elixir already on the machine
lib/elixir_utils.lua            version lists, downloads, the Erlang/OTP lookup, the Windows installer
lib/installed_version.lua       matching names against installed versions (PreUse)
lib/detect_elixir.lua           finding Elixir already on the machine (Detect)
lib/platform.lua                paths, shell commands and files that depend on the platform
tests/*_test.lua                offline hook tests, run by vfox plugin test
tests/post_install_layouts.lua  the shell commands of PostInstall, run with glua
tests/e2e/                      end-to-end tests in Go, see e2e.md
assets/                         version lists, the scripts that refresh them, hello.ex
website/                        the documentation site, in Chinese and English
docs/                           the documentation; README_CN.md and docs/zh-CN/ are the Chinese version
.github/workflows/              checks, tests, the release and the site
.devcontainer/                  the development container
Injection.lua                   type hints for what vfox injects, never loaded
```

vfox loads `metadata.lua`, calls a hook when a command needs it, and puts `PLUGIN` and `RUNTIME` in scope. `RUNTIME` has `osType`, `archType`, `version` and `pluginDirPath`. `osType` is `linux`, `darwin` or `windows`, and `archType` is the architecture of the vfox binary.

## What runs for a command

| You run | Hooks |
| --- | --- |
| `vfox search elixir` | `Available` |
| `vfox install elixir@1.16.2` | `PreInstall` returns the name and the URL. vfox downloads and unpacks the archive, then calls `PostInstall`, which builds Elixir (Linux, macOS) or runs the installer (Windows) |
| `vfox use elixir@1.16.2` | `PreUse` returns the installed name to select. `EnvKeys` provides `PATH` |
| `vfox link --detect elixir` | `Detect` returns the Elixir installations already on the machine |
| `vfox uninstall elixir@...` | no hook |

## Contracts

- `PreInstall` returns `version`, and `url` on Linux and macOS. On Windows it returns only `version`, because `PostInstall` downloads the installer. `version` is the name of the install.
- `PostInstall` takes the install directory from `ctx.sdkInfo['elixir'].path`. Do not build it from relative parts of other paths.
- `PreUse` returns `{ version = <installed name> }`. When nothing matches, it returns the typed name, and vfox reports `is not installed`.
- `EnvKeys` returns `PATH` set to `<path>/bin`, or to `<path>\bin` on Windows.
- `Detect` returns an array of `{ version = <name>, path = <install root>, note = <text> }`.
- `Available` returns an array of `{ version = <name> }`, with an optional `note`.

The vfox documentation describes the other fields of these hooks.

## Tests

`vfox plugin test .` runs the offline hook tests in `tests/*_test.lua`. It needs vfox 1.1.0 or later. Run it from the repository root.

`tests/post_install_layouts.lua` runs the shell commands of `PostInstall` in real directories, one of them with a space in its path, with a fake `make` and a fake `erlc` in the vfox cache. It is not a `*_test.lua` file, because vfox's test VM disables `os.execute` and `io.popen`. It runs under `gopher-lua`, the Lua interpreter that vfox embeds:

```bash
go run github.com/yuin/gopher-lua/cmd/glua@v1.1.1 tests/post_install_layouts.lua
```

The end-to-end suite in `tests/e2e` runs real vfox commands, see [e2e.md](e2e.md).

## Checks

The workflows in `.github/workflows/` run these checks. Run the same commands before you push.

- Lua formatting and static analysis: `stylua --check .` and `lua-language-server --check . --checklevel=Warning`.
- Go code in `tests/e2e`: `gofmt -l .` must print nothing, `go vet ./...` must pass on Linux and with `GOOS=windows`, and `go test -short ./...` runs the unit tests, which do not call vfox.
- Python scripts in `assets/` and `website/`: `ruff format --check` and `ruff check`, with ruff 0.15.0.
- Workflow files: `actionlint`, run with `go run github.com/rhysd/actionlint/cmd/actionlint@v1.7.7`.
- License headers: Apache SkyWalking Eyes, `license-eye header check`, configured by `.licenserc.yaml`.

## Dev container

`.devcontainer/` builds a development image from the official Go image. It has Go 1.27.1, the Erlang/OTP build packages, stylua, lua-language-server, license-eye and vfox 1.1.0, at the versions the workflows use. Open the repository in a Dev Containers tool such as VS Code. The image has neither ruff nor actionlint. The lint workflow installs ruff with pip and runs actionlint with `go run`, and you can do the same.

## Release

A maintainer publishes from **Actions → Plugin → Run workflow** on the default branch, entering a stable plugin version without the `v` prefix. The shared workflow, [plugin-manifest-action](https://github.com/version-fox/plugin-manifest-action), updates `metadata.lua`, creates the version commit and the tag, and publishes the ZIP and the manifest in this repository. No local tag or extra release token is needed. Pull requests run the checks only.

Pushing a version tag publishes too, when `PLUGIN.version` already matches the tag. If publication fails, re-run the failed job to resume it. `metadata.lua` keeps `PLUGIN.version = "1.0.0"` in the repository; the release workflow changes it.

## Website

The documentation site is built from `website/` with Python's standard library. See [website/README.md](../website/README.md).

## Writing the docs

English pages are in `docs/`, the Chinese pages are in `docs/zh-CN/` with the same file names, and each page starts with a link to the other language. A new page goes into the documentation list of both READMEs. No CI job checks these pages, so run the commands you add.
