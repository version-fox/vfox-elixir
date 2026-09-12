<div align="center">

![logo](./assets/vfox-elixir-logo.png)

[![vfox E2E tests](https://github.com/version-fox/vfox-elixir/actions/workflows/e2e_test.yaml/badge.svg)](https://github.com/version-fox/vfox-elixir/actions/workflows/e2e_test.yaml)
[![mise E2E tests](https://github.com/version-fox/vfox-elixir/actions/workflows/mise_e2e_test.yaml/badge.svg)](https://github.com/version-fox/vfox-elixir/actions/workflows/mise_e2e_test.yaml)

</div>

# vfox-elixir plugin

Elixir [vfox](https://github.com/version-fox) plugin. Use the vfox to manage multiple Elixir versions in Linux/Darwin MacOS/Windows. all platform~

## Usage

```shell
# install plugin
vfox add elixir

# install an available version
vfox search elixir
# or specific version 
vfox install elixir@1.16.2
```

## Before install Elixir

vfox-elixir plugin would install Elixir through the [Elixir](https://elixir-lang.org/install.html#compiling-from-source) source code compilation. So you must have the utilities mentioned in the document -> [Compiling from source](https://elixir-lang.org/install.html#compiling-from-source).

The installation of Elixir relies on Erlang/OTP. You can use the [vfox-erlang](https://github.com/version-fox/vfox-erlang) plugin to manage your Erlang/OTP versions.

Ensure that Elixir and Erlang/OTP versions are compatible -> [Elixir and Erlang/OTP compatibility](https://hexdocs.pm/elixir/1.16.2/compatibility-and-deprecations.html#between-elixir-and-erlang-otp). 

Here are two examples of installing on Ubuntu 20.04 and MacOS 13.

### install in Linux (Ubuntu 20.04/22.04)

```shell
# install utilities
sudo apt-get -y install build-essential autoconf m4 libncurses5-dev libwxgtk3.0-gtk3-dev libwxgtk-webview3.0-gtk3-dev libgl1-mesa-dev libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop libxml2-utils libncurses-dev openjdk-11-jdk

# install Erlang/OTP
vfox add erlang
vfox install erlang@26.2.3
vfox use -g erlang@26.2.3

# install Elixir
vfox add elixir
vfox install elixir@1.16.2
vfox use -g elixir@1.16.2
```

You can reference the E2E test in Ubuntu 20.04: [https://github.com/version-fox/vfox-elixir/actions/workflows/e2e_test.yaml](https://github.com/version-fox/vfox-elixir/actions/workflows/e2e_test.yaml)

### install in Darwin (MacOS 13)

```shell
# install utilities
brew install autoconf libxslt fop wxwidgets openssl

# install Erlang/OTP
vfox add erlang
vfox install erlang@26.2.3
vfox use -g erlang@26.2.3

# install Elixir
vfox add elixir
vfox install elixir@1.16.2
vfox use -g elixir@1.16.2
```

You can reference the E2E test in MacOS 13: [https://github.com/version-fox/vfox-elixir/actions/workflows/e2e_test.yaml](https://github.com/version-fox/vfox-elixir/actions/workflows/e2e_test.yaml)

## install Elixir in Windows platform

You should use vfox 0.5.3+ to add vfox-elixir plugin in Windows platform. **Only support install Elixir versions after v1.15**, Elixir versions before v1.15 can also be installed using the deprecated [Online Elixir Installer](https://github.com/elixir-lang/elixir-windows-setup/releases/tag/v2.4).

```shell
# make sure an Erlang/OTP version is installed.
vfox use -g erlang@26.2.3

# Get avaliable version
vfox search elixir

# install an specific version
vfox install elixir@1.16.2-elixir-otp-26
```

## install a pre-built version from hex.pm

You can also download a pre-built version from hex.pm. vfox-elixir will download it from: [https://github.com/hexpm/bob?tab=readme-ov-file#elixir-builds](https://github.com/hexpm/bob?tab=readme-ov-file#elixir-builds)

```shell
(1) > VFOX_ELIXIR_MIRROR=hex vfox search elixir
Please select a version of elixir to install [type to search]: 
->  vmain (pre-built from hex.pm)
   vmain-otp-22 (pre-built from hex.pm)
   vmain-otp-23 (pre-built from hex.pm)
   vmain-otp-24 (pre-built from hex.pm)
   vmain-otp-25 (pre-built from hex.pm)
   vmain-otp-26 (pre-built from hex.pm)
   vmain-otp-27 (pre-built from hex.pm)
   vmain-otp-28 (pre-built from hex.pm)
   vmaster (pre-built from hex.pm)

(1) > VFOX_ELIXIR_MIRROR=hex vfox install elixir@main-otp-26
```

## Usage with mise

The plugin can also be used with [mise](https://mise.jdx.dev/), a development tool manager:

```shell
# Elixir need Erlang/OTP, so install Erlang/OTP first
mise install vfox:version-fox/vfox-erlang@26.2.3
mise use -g vfox:version-fox/vfox-erlang@26.2.3

# Install an available version
mise install vfox:version-fox/vfox-elixir@1.16.2
```

## Releasing this plugin

Maintainers can publish from **Actions → Plugin → Run workflow** on the default
branch by entering a stable plugin version without the `v` prefix. The shared
workflow updates `metadata.lua`, creates the version commit and tag, and publishes
the ZIP and manifest in this repository. No local tag or extra release token is
needed. Pull requests run checks only; PR titles no longer trigger publication.

Existing version-tag pushes are supported when `PLUGIN.version` already matches
the tag. If publication fails, re-run the original failed job to resume it.

The workflow follows the shared `@v1` release-tool version. Updating the tool does
not release this plugin. See the [shared workflow documentation](https://github.com/version-fox/plugin-manifest-action)
for the package contract and first-rollout requirements.
