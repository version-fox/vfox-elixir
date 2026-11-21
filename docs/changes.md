[中文](zh-CN/changes.md) | [English](changes.md)

# Changes

What changed in each release, as a user notices it.

## Unreleased

### Added

- `vfox link --detect elixir` finds the Elixir already installed by the system, asdf, mise, Homebrew, Scoop or the official installer, and links it instead of installing another copy. It needs vfox 1.1.0 or later. See [link.md](link.md).
- Documentation in English and Chinese: versions, platforms, Erlang/OTP, hex prebuilt packages, linking, troubleshooting, development and the E2E tests.
- Offline hook tests, and checks of the Lua, Go and Python code, of the license headers and of the workflow files.
- E2E tests for Linux, macOS and Windows, and a development container (`.devcontainer`).
- The repository's `opencode.jsonc` adds allow rules for `git push`, `gh pr create` and `gh pr comment` for OpenCode sessions in this repository.

### Fixed

- Windows: an install failed when the vfox home path contains a space, because the installer path was not quoted.
- Windows: a release candidate such as `1.19.0-rc.2-elixir-otp-28` downloaded from a wrong address.
- Windows: the installer ran from a fixed relative path inside the plugin directory. It now runs against the install directory that vfox provides.
- Windows: a failed installer run reported `Erlang/OTP install failed`. The message now says Elixir.
- Windows: the installer file was left in the plugin directory after the install. It is now removed after the installer runs.
- Windows: the installer command passed PowerShell-only options (`-Wait -PassThru`) to the installer. They are removed.
- Linux and macOS: a source build failed when the install path contains a space.
- A network failure while the version list was fetched crashed the plugin. It now reports the error.
- The version-list script of the update workflow exited successfully when the GitHub API failed, which kept stale data. It now fails.
- The update workflow set a malformed git user name (`github-actions[bot]` written twice).
- Removed code that could never run: a check against a variable that vfox does not set, and an unused helper function.
- The plugin description shown by `vfox add` said "Uinx-like"; it now says "Unix-like".

### Changed

- Windows: `VFOX_ELIXIR_MIRROR=hex` stops with an error that Windows is not supported, before anything is downloaded. Before, the plugin tried to download the installer and failed.
- Windows: a version name that does not end in `-elixir-otp-<N>` is refused before anything is downloaded, with a hint to run `vfox search elixir`.
- `vfox use` for a version that is not installed reports `is not installed`. Before, it stopped with a Lua error.
- A name without an OTP suffix selects the installed build with the highest OTP number. `vfox use elixir@1.16.2` selects `1.16.2-otp-26` over `1.16.2-otp-25`, and `vfox use elixir@main` selects `main-otp-26` when it is installed.
- Source builds look for `erlc` in vfox's own Erlang cache too, and report what to install when no `erlc` is found.
