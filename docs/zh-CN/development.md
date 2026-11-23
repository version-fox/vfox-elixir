[中文](development.md) | [English](../development.md)

# 开发

## 目录结构

```
metadata.lua                    插件名、版本、依赖和备注
hooks/available.lua             vfox search
hooks/pre_install.lua           vfox install：版本名、下载地址和 hex.pm 的校验和
hooks/post_install.lua          vfox install：源码构建（Linux、macOS）或运行安装器（Windows）
hooks/pre_use.lua               vfox use：把输入的内容映射到已安装的名字
hooks/env_keys.lua              已安装版本的 PATH
hooks/detect.lua                vfox link --detect：本机已有的 Elixir
lib/elixir_utils.lua            版本列表、下载和校验和、Erlang/OTP 查找、Windows 安装器
lib/installed_version.lua       把名字与已安装的版本匹配（PreUse）
lib/detect_elixir.lua           查找本机已有的 Elixir（Detect）
lib/platform.lua                与平台相关的路径、Shell 命令和文件操作
tests/*_test.lua                离线的钩子测试，用 vfox plugin test 运行
tests/post_install_layouts.lua  PostInstall 的 Shell 命令，用 glua 运行
tests/e2e/                      Go 编写的端到端测试，见 e2e.md
assets/                         版本列表、刷新它们的脚本，以及 hello.ex
website/                        文档网站，中文和英文
docs/                           文档；README_CN.md 和 docs/zh-CN/ 是中文版
.github/workflows/              检查、测试、发布和网站
.devcontainer/                  开发容器
Injection.lua                   vfox 注入内容的类型提示，从不加载
```

vfox 会加载 `metadata.lua`，在命令需要时调用对应的钩子，并把 `PLUGIN` 和 `RUNTIME` 放入作用域。`RUNTIME` 包含 `osType`、`archType`、`version` 和 `pluginDirPath`。`osType` 是 `linux`、`darwin` 或 `windows`，`archType` 是 vfox 二进制文件的架构。

## 每个命令会调用哪些钩子

| 运行的命令 | 钩子 |
| --- | --- |
| `vfox search elixir` | `Available` |
| `vfox install elixir@1.16.2` | `PreInstall` 返回名字和下载地址。设置 `VFOX_ELIXIR_MIRROR=hex` 时，它还返回 `builds.txt` 中的 SHA-256。vfox 下载压缩包并用 SHA-256 校验；`PreInstall` 没有返回它时，只打印警告。然后解压，并调用 `PostInstall`，它会构建 Elixir（Linux、macOS）或运行安装器（Windows）。设置 `VFOX_ELIXIR_MIRROR=hex` 时它不构建任何东西，只打印名字没有 `-otp-N` 后缀的警告 |
| `vfox use elixir@1.16.2` | `PreUse` 返回要选中的已安装名字。`EnvKeys` 提供 `PATH` |
| `vfox link --detect elixir` | `Detect` 返回本机已有的 Elixir 安装 |
| `vfox uninstall elixir@...` | 没有钩子 |

## 契约

- `PreInstall` 返回 `version`；在 Linux 和 macOS 上还返回 `url`。设置 `VFOX_ELIXIR_MIRROR=hex` 时，还返回 `sha256`：`builds.txt` 为该 zip 发布的 SHA-256；索引中没有时则不返回。在 Windows 上只返回 `version`，因为安装器由 `PostInstall` 下载。`version` 就是安装后的名字。
- `PostInstall` 从 `ctx.sdkInfo['elixir'].path` 取得安装目录。不要用其他路径的相对部分拼出它。
- `PreUse` 返回 `{ version = <已安装的名字> }`。如果没有匹配，它返回输入的名字，由 vfox 报告 `is not installed`。
- `EnvKeys` 返回 `PATH`，值为 `<path>/bin`；在 Windows 上为 `<path>\bin`。
- `Detect` 返回由 `{ version = <名字>, path = <安装目录>, note = <备注> }` 组成的数组。
- `Available` 返回由 `{ version = <名字> }` 组成的数组，可以带可选的 `note`。`ctx.args` 是 `vfox search elixir` 后面的词：不带参数是源码版本，`hex` 表示 hex.pm 构建。vfox 按这些词缓存结果。

这些钩子的其他字段见 vfox 文档。

## 测试

`vfox plugin test .` 离线运行 `tests/*_test.lua` 中的钩子测试，需要 vfox 1.1.0 或更高版本。请在仓库根目录运行。

`tests/post_install_layouts.lua` 在真实目录中运行 `PostInstall` 使用的 Shell 命令，`make` 和 `erlc` 是放在 vfox 缓存中的假命令，并检查含空格或其他 Shell 字符的路径会在 `make` 运行前被拒绝。它不是 `*_test.lua` 文件，因为 vfox 的测试虚拟机禁用了 `os.execute` 和 `io.popen`。它在 `gopher-lua` 下运行，这是 vfox 内嵌的 Lua 解释器：

```bash
go run github.com/yuin/gopher-lua/cmd/glua@v1.1.1 tests/post_install_layouts.lua
```

`tests/e2e` 中的端到端测试会运行真实的 vfox 命令，见 [e2e.md](e2e.md)。

## 检查

`.github/workflows/` 中的工作流会运行以下检查。推送之前，请运行同样的命令。

- Lua 格式和静态分析：`stylua --check .` 和 `lua-language-server --check . --checklevel=Warning`。
- `tests/e2e` 中的 Go 代码：`gofmt -l .` 必须没有输出；`go vet ./...` 在 Linux 上和 `GOOS=windows` 下都必须通过；`go test -short ./...` 运行单元测试，它们不调用 vfox。
- `assets/` 和 `website/` 中的 Python 脚本：`ruff format --check` 和 `ruff check`，使用 ruff 0.15.0。
- 工作流文件：`actionlint`，用 `go run github.com/rhysd/actionlint/cmd/actionlint@v1.7.7` 运行。
- 许可证头：Apache SkyWalking Eyes，即 `license-eye header check`，配置在 `.licenserc.yaml` 中。

## 开发容器

`.devcontainer/` 基于官方 Go 镜像构建开发镜像。镜像中有 Go 1.27.1、Erlang/OTP 的构建依赖、stylua、lua-language-server、license-eye 和 vfox 1.1.0，版本与工作流中的一致。可以用 VS Code 等支持 Dev Containers 的工具打开本仓库。镜像中没有 ruff 和 actionlint。lint 工作流用 pip 安装 ruff，用 `go run` 运行 actionlint，你也可以这样做。

## 发布

维护者在默认分支上运行 **Actions → Plugin → Run workflow**，输入不带 `v` 前缀的稳定插件版本号即可发布。共享的工作流 [plugin-manifest-action](https://github.com/version-fox/plugin-manifest-action) 会更新 `metadata.lua`，创建版本提交和标签，并在本仓库发布 ZIP 和 manifest。不需要本地打标签，也不需要额外的发布令牌。Pull Request 只运行检查。

当 `PLUGIN.version` 已与标签一致时，推送版本标签也会发布。发布失败时，重新运行失败的任务即可继续。`metadata.lua` 中的 `PLUGIN.version` 由发布工作流修改，请不要手动改这一行。

## 网站

文档网站位于 `website/`，用 Python 标准库构建，见 [website/README.md](../../website/README.md)。

## 编写文档

英文页面在 `docs/` 中，中文页面在 `docs/zh-CN/` 中，文件名相同。每个页面的第一行都链接到另一种语言的版本。新页面要加入两个 README 的文档列表。没有 CI 任务检查这些页面，所以请自己运行你添加的命令。
