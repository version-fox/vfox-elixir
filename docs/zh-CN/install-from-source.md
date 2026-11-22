[中文](install-from-source.md) | [English](../install-from-source.md)

# 从源码安装

`vfox add elixir` 添加的是插件的最新发布版本。要在下一个版本发布之前试用 `main` 分支，或者试用你正在修改的代码，请从源码添加插件。插件就是 `metadata.lua` 加上 `hooks` 和 `lib` 目录，vfox 可以从 zip 文件或 zip 的 URL 添加它。

## 添加 main 分支

```bash
vfox add --source https://github.com/version-fox/vfox-elixir/archive/refs/heads/main.zip elixir
```

## 添加本地工作副本

要测试你自己的修改，请把插件文件打成 zip 再添加：

```bash
git clone --depth 1 https://github.com/version-fox/vfox-elixir.git
cd ./vfox-elixir/
zip -qr ./elixir.zip metadata.lua hooks lib
vfox add --source ./elixir.zip elixir
rm ./elixir.zip
```

在 Windows 上，可以在 PowerShell 中用 `tar` 打包。以下写法未在 Windows 上测试：

```powershell
git clone --depth 1 https://github.com/version-fox/vfox-elixir.git
cd ./vfox-elixir/
tar -a -cf ./elixir.zip metadata.lua hooks lib
vfox add --source ./elixir.zip elixir
Remove-Item ./elixir.zip
```

`--source` 可以是 `http://` 或 `https://` 的 URL，也可以是本地 `.zip` 或 `.lua` 文件的路径，不接受目录。

## 检查

Elixir 需要 Erlang/OTP，见 [erlang.md](erlang.md)。然后：

```bash
vfox install elixir@1.16.2
vfox use -g elixir@1.16.2
elixir --version
```

## 已经添加过 elixir

`vfox add` 会拒绝执行，并提示 `plugin named elixir already exists`。要替换插件，请先运行 `vfox remove elixir`。删除插件也会删除通过它安装的 Elixir 版本。vfox 会在询问之前说明这一点，所以之后需要重新安装这些版本。

## 更新

重新获取源码，再打成 zip，然后删除并重新添加插件。`vfox update elixir` 会比较 `metadata.lua` 中的版本与插件源中的版本，在发布更新的版本之前，它不会改动源码构建的插件。

要开发插件本身，请见 [development.md](development.md)。
