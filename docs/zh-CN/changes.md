[中文](changes.md) | [English](../changes.md)

# 变更记录

每个版本的变化，按用户能察觉到的方式记录。

## 未发布

### 修复

- 源码构建在 `make` 中失败时，提示不再打印退出码。原来打印的数字是 `os.execute` 的返回值，并不是 `make` 的退出状态。现在提示会说明 `make` 因错误而停止，并指向上方的输出（#37）。
- 在 Windows 上官方安装器失败时，提示同样不再打印退出码。原来打印的数字是 `os.execute` 的返回值，并不是安装器的退出状态。现在提示会说明安装器因错误而停止，并指向上方的输出（#37）。

## 1.0.3 - 2026-11-22

### 修复

- `VFOX_ELIXIR_MIRROR=hex` 时，`vfox install elixir@latest` 不再打印 `vfox search elixir hex` 的提示。vfox 对 `vfox search elixir` 和 `latest` 使用同样的方式调用这个钩子，钩子无法只在搜索时打印提示，因此搜索也不再打印它。`vfox search elixir hex` 仍会列出 hex.pm 构建（#35）。
- `VFOX_ELIXIR_MIRROR=hex` 时，名字没有 `-otp-N` 后缀的警告改为在构建下载之后打印，而不是之前。hex.pm 没有的名字只会得到下载错误（#35）。

## 1.0.2 - 2026-11-22

### 修复

- Linux 和 macOS：vfox 主目录的路径含空格或其他会被 Shell 解释的字符时，源码构建在调用 `make` 之前停止。Elixir 的 Makefile 无法在这样的路径上构建，以前构建会在 `make` 中失败。文档曾说 Elixir 的安装在所有平台上都能处理 vfox 主目录中的空格，这对源码构建并不成立（#31）。
- `VFOX_ELIXIR_MIRROR=hex` 时，`latest` 被解析为 `1.20-latest`，而 hex.pm 没有它的构建，安装在下载时失败。现在安装会在下载前停止，并提示改装一个构建（#27）。
- `vfox search elixir hex` 只列出名字带 OTP 后缀的构建，例如 `1.16.2-otp-26`。没有后缀的构建（例如 `1.20.5`）可能拒绝在另一个 Erlang/OTP 下运行，因此不再列出（#28）。
- `VFOX_ELIXIR_MIRROR=hex` 时，提示 `vfox search elixir hex` 输出到标准错误，不再混入版本列表（#29）。
- 服务器以状态 200 返回纯文本的版本列表（例如 `Error code: 404`）时，插件不再把它列为版本或写入缓存。搜索和安装都会给出与错误页相同的提示（#30）。
- README 曾写插件会管理每个版本所需的 Erlang/OTP。插件并不安装 Erlang/OTP，README 现已说明这一点（#32）。

### 变更

- `VFOX_ELIXIR_MIRROR=hex` 时，`vfox install` 会打印构建所需的 Erlang/OTP；名字没有 OTP 后缀时会给出警告，因为该构建可能拒绝在另一个 Erlang/OTP 下运行（#28）。

## 1.0.1 - 2026-11-22

### 新增

- `vfox link --detect elixir` 可以找到已由系统、asdf、mise、Homebrew、Scoop 或官方安装器装在本机的 Elixir，并链接它，而不是再安装一份。需要 vfox 1.1.0 或更高版本。见 [link.md](link.md)。
- 中英文文档：版本、平台、Erlang/OTP、Hex 预编译包、链接已有安装、问题排查、开发和 E2E 测试。
- 离线的钩子测试，以及对 Lua、Go 和 Python 代码、许可证头和工作流文件的检查。
- Linux、macOS 和 Windows 上的 E2E 测试，以及一个开发容器（`.devcontainer`）。
- 仓库中的 `opencode.jsonc` 为本仓库中的 OpenCode 会话添加了 `git push`、`gh pr create` 和 `gh pr comment` 的允许规则。

### 修复

- Windows：vfox 主目录的路径含空格时安装失败，因为安装器路径没有加引号。
- Windows：`1.19.0-rc.2-elixir-otp-28` 这类预发布版本会从错误的地址下载。
- Windows：安装器从插件目录内的固定相对路径运行。现在它在 vfox 提供的安装目录中运行。
- Windows：安装器运行失败时报的是 `Erlang/OTP install failed`，现在改为提示 Elixir。
- Windows：安装成功后，安装包残留在插件目录中。现在安装器运行之后会被删除。
- Windows：安装命令把只属于 PowerShell 的选项（`-Wait -PassThru`）传给了安装器。现已删除。
- Linux 和 macOS：安装路径含空格时，源码构建失败，或者在错误的目录中运行 `make` 并报告成功（#20）。
- 获取版本列表时如果网络出错，插件会崩溃。现在会报告错误。服务器返回的错误页或空的应答曾被列为版本并写入缓存；现在插件会以状态码或错误信息停止（#22）。
- 更新工作流中的版本列表脚本在 GitHub API 失败时仍以成功退出，于是保留了旧数据。现在会以失败退出。
- 更新工作流设置的 git 用户名格式错误（`github-actions[bot]` 被重复写了一遍）。
- 删除了永远不会执行的代码：一处对 vfox 不会设置的变量的检查，以及一个没有被使用的辅助函数。
- `vfox add` 显示的插件描述把 "Unix" 写成了 "Uinx"，现已更正。
- 网站和文档中的 `vfox exec` 示例在运行 `elixir` 时没有带上 Erlang/OTP，结果报 `exec: erl: not found`。现在示例中写出了 Erlang/OTP（#24）。

### 变更

- Windows：`VFOX_ELIXIR_MIRROR=hex` 会在下载任何内容之前直接报错，说明 Windows 不支持。之前插件会尝试下载安装器并失败。
- Windows：版本名不以 `-elixir-otp-<N>` 结尾时，会在下载之前被拒绝，并提示运行 `vfox search elixir`。
- `vfox use` 选择的版本未安装时，报告 `is not installed`。之前它会以 Lua 错误停止（#21）。
- 不带 OTP 后缀的名字会选中 OTP 编号最大的已安装构建。`vfox use elixir@1.16.2` 选中 `1.16.2-otp-26` 而不是 `1.16.2-otp-25`；安装了 `main-otp-26` 时，`vfox use elixir@main` 选中它。
- 源码构建时查找 `erlc`，也会搜索 vfox 自己的 Erlang 缓存。找不到 `erlc` 时，报错会说明需要安装什么（#23）。
- `vfox search elixir hex` 列出 hex.pm 构建。`VFOX_ELIXIR_MIRROR` 不再改变搜索列表，只影响安装：vfox 按搜索参数缓存结果，因此 hex.pm 构建和源码版本列表不再互相显示（#22）。
