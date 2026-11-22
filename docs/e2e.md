[中文](zh-CN/e2e.md) | [English](e2e.md)

# E2E tests

The end-to-end suite in `tests/e2e` uses the real `vfox` on the host to install Erlang/OTP and Elixir, then runs a small Elixir program with each install. It is a Go program that uses only the standard library, and it does not start containers. CI runs it on the host runners:

| Runner | Covers |
| --- | --- |
| `ubuntu-24.04`, `ubuntu-24.04-arm` | Linux: source builds and hex prebuilt packages |
| `macos-latest` | macOS: source builds and hex prebuilt packages |
| `windows-latest` | Windows: the official installer, and the refusal of hex packages |

The workflow is `.github/workflows/e2e.yml`. The suite adds the plugin from the working tree, so the tests check the code that you push.

## Run it locally

You need vfox 1.1.0 or later and Go 1.27.1. In `tests/e2e`:

```bash
cd tests/e2e
go test -v -timeout 90m -run TestE2E ./...
```

`go test -short ./...` runs only the unit tests, which do not call vfox. Short mode skips `TestE2E`.

The dev container in `.devcontainer/` has Go 1.27.1, vfox 1.1.0 and the Erlang/OTP build packages, so the same command runs there, see [development.md](development.md#dev-container).

### In an Ubuntu container

`tests/e2e/linux/Dockerfile` builds an Ubuntu 24.04 image with Go, the Erlang/OTP build packages and vfox 1.1.0. The vfox archive is checked against its SHA-256. The repository is mounted read-only. The suite writes only to temporary directories and to `E2E_VFOX_HOME`. Run these commands from the repository root. The build context is `tests/e2e/linux`, not the whole repository:

```bash
docker build -f tests/e2e/linux/Dockerfile -t vfox-elixir-e2e:ubuntu-24.04 tests/e2e/linux
docker run --rm -v "$PWD:/src:ro" -v vfox-elixir-e2e-cache:/cache -e E2E_VFOX_HOME=/cache/vfox-home -w /src/tests/e2e vfox-elixir-e2e:ubuntu-24.04 go test -v -timeout 90m -run TestE2E ./...
```

The named volume keeps the vfox home between runs, so an Erlang/OTP that is already built is reused. The home path has no space, because the suite refuses one, see below.

## Environment variables

| Variable | Default | Meaning |
| --- | --- | --- |
| `VFOX_BIN` | `vfox` on `PATH` | the vfox binary to test |
| `E2E_VFOX_HOME` | a new temporary directory, removed at the end | the vfox home (`VFOX_HOME`). When it is set, the directory is used as it is and kept, so a cache volume can hold Erlang/OTP. The path must not contain a space, and the suite refuses one: on Linux and macOS, OTP's `configure` does not quote its paths, and on Windows the Erlang/OTP and Elixir steps do not run `erl.exe` or `elixir.bat` from such a path |
| `E2E_ERLANG_VERSION` | `26.2.3` | the Erlang/OTP version to install. Its major version is the OTP release that the suite checks for |
| `E2E_ELIXIR_VERSION` | `1.16.2` | the Elixir version of the source and hex installs |
| `E2E_ERLANG_SOURCE` | `https://github.com/version-fox/vfox-erlang/archive/refs/heads/main.zip` | where `vfox add` gets the `erlang` plugin |

The default home is named `vfox-home-…` on every platform, and its path has no space. On Windows the space case is checked by the step `installer in a spaced home`, which installs Elixir into a home named `vfox home-…`. That step needs no Erlang/OTP.

Each vfox process starts without the variables whose names begin with `VFOX_` or `__VFOX_`, so the vfox settings of your shell do not change the run. Each process also gets `HOME` and `USERPROFILE` set to temporary directories that the suite creates, so your real home directory is never read or written.

## What the suite runs

The steps below run in order, and each one logs its commands and their output. A command that downloads (`vfox add` of the Erlang/OTP plugin, and every `vfox install`) is tried up to five times, 10 seconds apart, when the download fails on the network. Any other failure, such as a build that fails, stops the test at once.

1. **vfox version** prints the version of vfox under test. It asserts nothing.
2. **add plugins** removes an Elixir plugin left by an earlier run in the same home, together with its installs, then adds `elixir` from a zip of `metadata.lua`, `hooks/*.lua` and `lib/*.lua` in the working tree. It adds `erlang` from `E2E_ERLANG_SOURCE`, unless the home already has that plugin.
3. **installer in a spaced home** (Windows only) installs Elixir into a new home whose path has a space, from the same zip, and checks that the installer wrote `VERSION` and `bin\elixir.bat` under the install directory. It needs no Erlang/OTP. The step is skipped on Linux and macOS.
4. **erlang** installs `erlang@<E2E_ERLANG_VERSION>`. If the home already has it and `erl` reports the OTP major version, the install is skipped. Otherwise it is installed again. Then the suite checks that `erl` reports that major version.
5. **elixir** installs Elixir and runs `hello.ex` with it:
   - Linux and macOS: `vfox install elixir@1.16.2`, then `vfox exec erlang@26.2.3 elixir@1.16.2 -- elixir hello.ex`.
   - Windows: `vfox install elixir@1.16.2-elixir-otp-26`, then `vfox exec erlang@26.2.3 elixir@1.16.2-elixir-otp-26 -- elixir.bat hello.ex`.

   `hello.ex` is a copy of `assets/hello.ex`, made in a new directory. The output must contain `Hello world from Elixir`.
6. **hex mirror**:
   - Linux and macOS: `VFOX_ELIXIR_MIRROR=hex vfox install elixir@1.16.2-otp-26`, then the program runs as in step 4.
   - Windows: the same install must fail, and its output must mention Windows.
7. **search lists** runs `vfox search elixir`, then `vfox search elixir hex`, then `vfox search elixir` again, in one home. The first and the last list the releases only. On Linux and macOS the middle one lists the hex.pm builds, each noted `pre-built from hex.pm`. On Windows it fails, and says that the hex.pm builds are not available on Windows.
8. **use not installed** runs `vfox use -g` with `elixir@9.9.9` and `elixir@9.9`, neither of which is installed. Each must fail with `is not installed`, and print no Lua traceback.
9. **detect** creates a fake Elixir installation in the suite's home directory. It has a launcher that prints `Elixir 1.99.0 (fake)`, and a `VERSION` file that says `1.99.0`.
   - Linux and macOS: `bin/elixir` under `$HOME/.asdf/installs/elixir/1.99.0-otp-26`. asdf names an installation after its directory, so the name is `1.99.0-otp-26`.
   - Windows: `bin\elixir.bat` under `%USERPROFILE%\scoop\apps\elixir\1.99.0`. Scoop names an installation after `VERSION`, so the name is `1.99.0`.

   `vfox link --detect -y elixir` must list the installation, and `vfox exec elixir@<name> -- elixir --version` must print `Elixir 1.99.0 (fake)`. On Windows the program is `elixir.bat`.

The files `platform_unix.go` and `platform_windows.go` hold what differs between the platforms: the layout and launcher of the fake installation, the names of the official and hex installs, the names of the programs that run through `vfox exec`, and whether the home may hold a space. On Windows those names keep their extension (`erl.exe`, `elixir.bat`), because vfox 1.1.0 finds a command in the PATH of the SDKs only by the name as typed.

## How long it takes

Erlang/OTP is built from source, so a first run can take 20 minutes or more. Set `E2E_VFOX_HOME` to a directory that you keep, so that later runs reuse the Erlang/OTP install.
