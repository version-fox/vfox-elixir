[中文](versions.md) | [English](../versions.md)

# 版本与命名

`elixir@` 后面写的是版本名。版本名取决于构建的来源：

| 来源 | 版本名示例 | 安装的内容 |
| --- | --- | --- |
| 源码，Linux 和 macOS | `1.16.2` | GitHub 标签 `v1.16.2` 的源码包，用 `make` 编译 |
| Hex 预编译包，Linux 和 macOS（`VFOX_ELIXIR_MIRROR=hex`） | `1.16.2-otp-26`、`main-otp-26` | builds.hex.pm 上的预编译 zip |
| 官方安装器，Windows | `1.16.2-elixir-otp-26` | GitHub 发行版 `v1.16.2` 中的 `elixir-otp-26.exe` |

```bash
vfox search elixir                                         # 可以安装的名字
vfox search elixir hex                                     # hex.pm 构建，Linux 和 macOS
vfox install elixir@1.16.2                                 # 源码构建，Linux 和 macOS
VFOX_ELIXIR_MIRROR=hex vfox install elixir@1.16.2-otp-26   # Hex 预编译包，Linux 和 macOS
vfox install elixir@1.16.2-elixir-otp-26                   # Windows
vfox use -g elixir@1.16.2                                  # 设为全局默认
vfox list elixir                                           # 已安装的名字
vfox uninstall elixir@1.16.2                               # 删除一个已安装的名字
```

## OTP 后缀

Hex 和 Windows 的版本名以 `-otp-<N>` 或 `-elixir-otp-<N>` 结尾。`<N>` 是构建所针对的 Erlang/OTP 主版本。请先安装这个 Erlang/OTP，见 [erlang.md](erlang.md)。

源码版本名没有后缀。安装时，它们用插件找到的 `erlc` 编译，同样见 [erlang.md](erlang.md)。

## 安装后的名字

你写的版本名就是安装后的名字。`vfox install elixir@1.16.2-otp-26` 会装到 `1.16.2-otp-26` 下，`vfox list elixir` 显示的也是这个名字。插件不会改名。

`vfox search` 会去掉 builds.txt 中版本前面的 `v`：`v1.16.2-otp-26` 列为 `1.16.2-otp-26`。下载时，以数字开头的名字会加回 `v`，即 `1.16.2-otp-26` 下载 `v1.16.2-otp-26.zip`。

## 搜索

`vfox search elixir` 列出当前平台可以安装的名字：

- Linux 和 macOS：仓库中 `assets/versions.txt` 的名字。
- Windows：`assets/versions_win.txt` 的名字。
- `vfox search elixir hex`：[builds.txt](https://builds.hex.pm/builds/elixir/builds.txt) 中的名字，即 Linux 和 macOS 的 hex.pm 构建。

仓库里的两个列表由定时工作流每周更新。vfox 默认缓存 `vfox search` 的结果 12 小时（配置项 `cache.availableHookDuration`），所以刚发布的版本可能暂时看不到。缓存按搜索参数分别保存：源码版本列表和 hex.pm 构建列表各有一份。

## 使用版本

`vfox use` 从已安装的名字中选择：

- 完整的已安装名字原样使用，例如 `vfox use -g elixir@1.16.2-otp-26`。
- 不带 OTP 后缀的名字（如 `1.16.2` 或 `main`）：若已安装同名版本（源码构建），就用它。否则选择 OTP 编号最大的已安装构建：`1.16.2` 对应 `1.16.2-otp-<N>` 或 `1.16.2-elixir-otp-<N>`，`main` 对应 `main-otp-<N>`。例如同时安装了 `1.16.2-otp-25` 和 `1.16.2-otp-26`，`vfox use elixir@1.16.2` 选中 `1.16.2-otp-26`。编号相同的两个构建同时存在时，选名字排在前面的那个。
- 匹配的是完整的版本号：`1.16` 不会选中 `1.16.2-otp-26`。
- 其他情况报 `elixir@<版本> is not installed`。

作用域用 `vfox use` 的参数选择：`-g`（全局）、`-p`（项目，写入 `.vfox.toml`）。不写参数时作用于当前 Shell，这需要已挂载 vfox 的 Shell 钩子，见 `vfox activate`。

`vfox exec` 不做这种映射，它只按已安装的完整名字查找。因此 `vfox exec elixir@1.16.2 -- elixir --version` 会去安装源码版 `1.16.2`，而不是运行 `1.16.2-otp-26`。用 `exec` 时请写完整名字，例如 `vfox exec erlang@26.2.3 elixir@1.16.2-otp-26 -- elixir --version`：`elixir` 还需要 Erlang/OTP，而 `exec` 只把 Elixir 的目录加入 `PATH`。也可以在已挂载钩子的 Shell 中用 `vfox use` 选中两者，然后直接运行 `elixir`。Windows 上程序名需要带扩展名 `elixir.bat`，见 [troubleshooting.md](troubleshooting.md#vfox-exec-在-windows-上找不到-erl-或-elixir)。

## 预发布版本

预发布版本使用同样的格式：Linux 和 macOS 上是 `1.20.0-rc.6`，Windows 上是 `1.19.0-rc.2-elixir-otp-28`。
