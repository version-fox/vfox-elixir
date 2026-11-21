[中文](e2e.md) | [English](../e2e.md)

# E2E 测试

`tests/e2e` 中的端到端测试在宿主机上使用真实的 `vfox` 安装 Erlang/OTP 和 Elixir，然后用每个安装运行一个小的 Elixir 程序。它是只使用 Go 标准库的程序，不启动容器。CI 直接在宿主机的 runner 上运行它：

| Runner | 覆盖的内容 |
| --- | --- |
| `ubuntu-24.04`、`ubuntu-24.04-arm` | Linux：源码构建和 Hex 预编译包 |
| `macos-latest` | macOS：源码构建和 Hex 预编译包 |
| `windows-latest` | Windows：官方安装器，以及拒绝 Hex 预编译包 |

运行它的工作流是 `.github/workflows/e2e.yml`。测试从工作区添加插件，所以测试的是你推送的代码。

## 本地运行

需要 vfox 1.1.0 或更高版本，以及 Go 1.27.1。在 `tests/e2e` 中运行：

```bash
cd tests/e2e
go test -v -timeout 90m -run TestE2E ./...
```

`go test -short ./...` 只运行单元测试，它们不调用 vfox。短模式会跳过 `TestE2E`。

`.devcontainer/` 中的开发容器带有 Go 1.27.1、vfox 1.1.0 和 Erlang/OTP 的构建依赖，因此同样的命令可以在容器中运行，见 [开发](development.md#开发容器)。

### 在 Ubuntu 容器中运行

`tests/e2e/linux/Dockerfile` 会构建一个 Ubuntu 24.04 镜像，其中包含 Go、Erlang/OTP 的构建依赖以及 vfox 1.1.0。vfox 的归档文件会用 SHA-256 校验。仓库以只读方式挂载，测试只写入临时目录和 `E2E_VFOX_HOME`。请在仓库根目录运行以下命令。构建上下文是 `tests/e2e/linux`，而不是整个仓库：

```bash
docker build -f tests/e2e/linux/Dockerfile -t vfox-elixir-e2e:ubuntu-24.04 tests/e2e/linux
docker run --rm -v "$PWD:/src:ro" -v vfox-elixir-e2e-cache:/cache -e E2E_VFOX_HOME=/cache/vfox-home -w /src/tests/e2e vfox-elixir-e2e:ubuntu-24.04 go test -v -timeout 90m -run TestE2E ./...
```

命名卷会在两次运行之间保留 vfox 主目录，因此已经编译好的 Erlang/OTP 会被复用。这里的主目录路径不含空格，因为 Linux 上测试会拒绝含空格的路径，见下文。

## 环境变量

| 变量 | 默认值 | 含义 |
| --- | --- | --- |
| `VFOX_BIN` | `PATH` 上的 `vfox` | 要测试的 vfox 可执行文件 |
| `E2E_VFOX_HOME` | 新建的临时目录，结束时删除 | vfox 主目录（`VFOX_HOME`）。设置之后，该目录按原样使用并保留，因此缓存卷可以保存 Erlang/OTP。路径不能含空格，测试会拒绝含空格的路径：Linux 和 macOS 上 OTP 的 `configure` 不会给路径加引号；Windows 上，CI 中官方 Erlang/OTP 安装器装到含空格的主目录后，`vfox exec` 找不到 `erl.exe` |
| `E2E_ERLANG_VERSION` | `26.2.3` | 要安装的 Erlang/OTP 版本。它的主版本号就是测试检查的 OTP 版本 |
| `E2E_ELIXIR_VERSION` | `1.16.2` | 源码安装和 Hex 安装所用的 Elixir 版本 |
| `E2E_ERLANG_SOURCE` | `https://github.com/version-fox/vfox-erlang/archive/refs/heads/main.zip` | `vfox add` 获取 `erlang` 插件的来源 |

默认主目录在所有平台上都叫 `vfox-home-…`，且路径不含空格。Windows 上的空格情况由步骤 `installer in a spaced home` 检查，它把 Elixir 安装到名为 `vfox home-…`（含空格）的主目录中。这一步不需要 Erlang/OTP。

每个 vfox 进程启动时都不带名字以 `VFOX_` 或 `__VFOX_` 开头的变量，因此你 Shell 中的 vfox 设置不会改变测试结果。每个进程的 `HOME` 和 `USERPROFILE` 也都指向测试创建的临时目录，因此你真正的主目录永远不会被读取或写入。

## 测试执行的内容

下面的步骤按顺序执行，每一步都会记录它运行的命令和输出。需要下载的命令（Erlang/OTP 插件的 `vfox add` 和所有 `vfox install`）在下载因网络失败时最多尝试五次，每次间隔 10 秒。其他失败（例如编译失败）会立即停止测试。

1. **vfox version** 输出被测 vfox 的版本号，不做断言。
2. **add plugins** 先删除同一主目录中上次运行留下的 Elixir 插件及其安装，然后从工作区中 `metadata.lua`、`hooks/*.lua` 和 `lib/*.lua` 打成的 zip 添加 `elixir`。如果主目录中还没有 `erlang` 插件，则从 `E2E_ERLANG_SOURCE` 添加它。
3. **installer in a spaced home**（仅 Windows）从同一个 zip 把 Elixir 安装到路径含空格的新主目录中，并检查安装器在安装目录中写出了 `VERSION` 和 `bin\elixir.bat`。这一步不需要 Erlang/OTP。在 Linux 和 macOS 上跳过这一步。
4. **erlang** 安装 `erlang@<E2E_ERLANG_VERSION>`。如果主目录中已经有它，并且 `erl` 报告的 OTP 主版本号正确，则跳过安装；否则重新安装。然后检查 `erl` 报告的是该主版本号。
5. **elixir** 安装 Elixir，并用它运行 `hello.ex`：
   - Linux 和 macOS：`vfox install elixir@1.16.2`，然后运行 `vfox exec erlang@26.2.3 elixir@1.16.2 -- elixir hello.ex`。
   - Windows：`vfox install elixir@1.16.2-elixir-otp-26`，然后用这个名字运行同样的程序。

   `hello.ex` 是 `assets/hello.ex` 在新目录中的副本。输出必须包含 `Hello world from Elixir`。
6. **hex mirror**：
   - Linux 和 macOS：`VFOX_ELIXIR_MIRROR=hex vfox install elixir@1.16.2-otp-26`，然后像第 4 步那样运行程序。
   - Windows：同一条安装命令必须失败，并且输出中要提到 Windows。
7. **detect** 在测试的主目录中创建一个假的 Elixir 安装。它有一个启动脚本，输出 `Elixir 1.99.0 (fake)`，还有一个内容为 `1.99.0` 的 `VERSION` 文件。
   - Linux 和 macOS：`$HOME/.asdf/installs/elixir/1.99.0-otp-26` 下的 `bin/elixir`。asdf 以目录名命名安装，所以名字是 `1.99.0-otp-26`。
   - Windows：`%USERPROFILE%\scoop\apps\elixir\1.99.0` 下的 `bin\elixir.bat`。Scoop 以 `VERSION` 命名安装，所以名字是 `1.99.0`。

   `vfox link --detect -y elixir` 必须列出这个安装，并且 `vfox exec elixir@<名字> -- elixir --version` 必须输出 `Elixir 1.99.0 (fake)`。

`platform_unix.go` 和 `platform_windows.go` 保存了各平台之间不同的部分：假安装的目录结构和启动脚本、官方安装和 Hex 安装所用的名字，以及主目录是否允许含空格。

## 需要多长时间

Erlang/OTP 从源码构建，所以第一次运行可能需要 20 分钟以上。把 `E2E_VFOX_HOME` 设为一个你保留的目录，之后的运行就能复用 Erlang/OTP 的安装。
