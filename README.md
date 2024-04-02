# vfox-elixir plugin

Elixir [vfox](https://github.com/version-fox) plugin. Use the vfox to manage multiple Elixir versions in Linux/Darwin.

## Usage

```shell
# install plugin
vfox add --source https://github.com/yeshan333/vfox-elixir/archive/refs/heads/main.zip elixir

# install an available version
vofx search elixir
# or specific version 
vfox install elixir@1.16.2
```

## Before install Elixir

vfox-elixir plugin would install Elixir through the [Elixir](https://elixir-lang.org/install.html#compiling-from-source) source code compilation. So you must have the utilities mentioned in the document -> [Compiling from source](https://elixir-lang.org/install.html#compiling-from-source).

The installation of Elixir relies on Erlang/OTP. You can use the [vfox-erlang](https://github.com/yeshan333/vfox-erlang) plugin to manage your Erlang/OTP versions.

Ensure that Elixir and Erlang/OTP versions are compatible -> [Elixir and Erlang/OTP compatibility](https://hexdocs.pm/elixir/1.16.2/compatibility-and-deprecations.html#between-elixir-and-erlang-otp). 

Here are two examples of installing on Ubuntu 20.04 and MacOS 13.

### install in Linux (Ubuntu 20.04)

```shell
# install utilities
sudo apt-get -y install build-essential autoconf m4 libncurses5-dev libwxgtk3.0-gtk3-dev libwxgtk-webview3.0-gtk3-dev libgl1-mesa-dev libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop libxml2-utils libncurses-dev openjdk-11-jdk

# install Erlang/OTP
vfox add --source https://github.com/yeshan333/vfox-erlang/archive/refs/heads/main.zip erlang
vfox install erlang@26.2.3
vfox use -g erlang@26.2.3

# install Elixir
vfox add --source https://github.com/yeshan333/vfox-elixir/archive/refs/heads/main.zip elixir
vfox install elixir@1.16.2
vfox use -g elixir@1.16.2
```

You can reference the E2E test in Ubuntu 20.04: [https://github.com/yeshan333/vfox-elixir/actions/workflows/e2e_test.yaml](https://github.com/yeshan333/vfox-elixir/actions/workflows/e2e_test.yaml)

### install in Darwin (MacOS 13)

```shell
# install utilities
brew install autoconf libxslt fop wxwidgets openssl

# install Erlang/OTP
vfox add --source https://github.com/yeshan333/vfox-erlang/archive/refs/heads/main.zip erlang
vfox install erlang@26.2.3
vfox use -g erlang@26.2.3

# install Elixir
vfox add --source https://github.com/yeshan333/vfox-elixir/archive/refs/heads/main.zip elixir
vfox install elixir@1.16.2
vfox use -g elixir@1.16.2
```

You can reference the E2E test in MacOS 13: [https://github.com/yeshan333/vfox-elixir/actions/workflows/e2e_test.yaml](https://github.com/yeshan333/vfox-elixir/actions/workflows/e2e_test.yaml)