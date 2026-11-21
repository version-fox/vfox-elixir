# CLAUDE.md

This file gives guidance to coding agents working in this repository.

## Project overview

vfox-elixir is a [vfox](https://vfox.dev) plugin that installs and selects Elixir
versions on Linux, macOS and Windows. Elixir is compiled from source on Unix-like
systems (it needs Erlang/OTP), installed from the official installer on Windows,
or taken as a prebuilt zip from hex.pm with `VFOX_ELIXIR_MIRROR=hex`. The plugin
also finds Elixir installations that are already on the machine (`vfox link --detect elixir`).

The user-facing documentation is in `README.md` and `docs/`; the Chinese versions are
`README_CN.md` and `docs/zh-CN/`. Keep both languages in step.

## Layout

- `metadata.lua`: plugin name, version, dependencies and notes. Do not rename it.
- `hooks/`: the vfox hooks. `available.lua`, `pre_install.lua`, `post_install.lua`,
  `pre_use.lua`, `env_keys.lua`, `detect.lua` (for `vfox link --detect`).
- `lib/`: shared modules. `platform.lua` (paths, shell quoting, command output),
  `elixir_utils.lua` (version lists, URLs, build and installer commands, Erlang/OTP lookup),
  `installed_version.lua` (matching a typed version against installed names),
  `detect_elixir.lua` (finding installations that vfox did not install).
- `tests/*_test.lua`: offline hook tests, run by `vfox plugin test .` (vfox 1.1.0).
  `tests/post_install_layouts.lua` runs the real PostInstall shell under glua.
- `tests/e2e/`: the end-to-end suite, a Go program using only the standard library. It drives
  vfox on the host; see `docs/e2e.md`.
- `assets/`: version lists updated weekly by `update_elixir_versions.yaml`, and `hello.ex`,
  the program the E2E suite runs.
- `website/`: the bilingual GitHub Pages site, built by `website/build.py`.
- `Injection.lua`: type hints for what vfox injects. Never loaded.

## Local checks

```bash
stylua --check .                                   # Lua formatting (stylua.toml)
lua-language-server --check . --checklevel=Warning # Lua types
vfox plugin test .                                 # offline hook tests, with vfox 1.1.0
go run github.com/yuin/gopher-lua/cmd/glua@v1.1.1 tests/post_install_layouts.lua
(cd tests/e2e && gofmt -l . && go vet ./... && GOOS=windows go vet ./... && go test -short ./...)
ruff format --check assets website && ruff check assets website   # Python
license-eye header check -c .licenserc.yaml        # license headers
```

Run the E2E suite (`tests/e2e`, `-run TestE2E`) only when the change can affect an install:
it compiles Erlang/OTP, which takes a long time. `docs/e2e.md` has the commands, including
one for a temporary Ubuntu container.

## Conventions

- Every source file carries the Apache-2.0 header from `.licenserc.yaml`. Documentation,
  JSON, TXT and PNG files are exempt.
- Lua runs under vfox's Lua 5.1 (gopher-lua). Use `platform.lua` for paths and shell
  commands; quote every path that goes into a shell command.
- A test that calls `pcall` must come last in its file: gopher-lua closures stop seeing
  later assignments to the locals around them once `pcall` has caught an error.
- Version names: source builds `1.16.2`, hex.pm builds `1.16.2-otp-26`, Windows installers
  `1.16.2-elixir-otp-26`. A release typed without its OTP release selects the newest build of it.
- `vfox` tests and hooks must not assume the real HOME or USERPROFILE: tests set them.
- Do not add Windows installer logic that depends on Erlang/OTP being registered in the registry;
  the silent installer does not need it.
