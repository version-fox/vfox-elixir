[中文](zh-CN/install-from-source.md) | [English](install-from-source.md)

# Install from source

`vfox add elixir` installs the latest release. To try the `main` branch before the next release, or a change you are working on, add the plugin from source. A plugin is `metadata.lua` plus the `hooks` and `lib` directories, and vfox can add one from a zip file or a zip URL.

## Add the main branch

```bash
vfox add --source https://github.com/version-fox/vfox-elixir/archive/refs/heads/main.zip elixir
```

## Add a working copy

To test your own changes, zip the plugin files and add the zip:

```bash
git clone --depth 1 https://github.com/version-fox/vfox-elixir.git
cd ./vfox-elixir/
zip -qr ./elixir.zip metadata.lua hooks lib
vfox add --source ./elixir.zip elixir
rm ./elixir.zip
```

On Windows, in PowerShell, the zip can be made with `tar`. This form was not tested on Windows:

```powershell
git clone --depth 1 https://github.com/version-fox/vfox-elixir.git
cd ./vfox-elixir/
tar -a -cf ./elixir.zip metadata.lua hooks lib
vfox add --source ./elixir.zip elixir
Remove-Item ./elixir.zip
```

vfox accepts an `http://` or `https://` URL, or a path to a local `.zip` or `.lua` file, for `--source`. It does not accept a directory.

## Check it

Elixir needs Erlang/OTP, see [erlang.md](erlang.md). Then:

```bash
vfox install elixir@1.16.2
vfox use -g elixir@1.16.2
elixir --version
```

## When elixir is already added

`vfox add` refuses with `plugin named elixir already exists`. To replace the plugin, run `vfox remove elixir` first. Removing a plugin also removes the Elixir versions installed through it. vfox says so before it asks, so reinstall them afterwards.

## Updating

Pull or download the source again, zip it again, and remove and add the plugin. `vfox update elixir` compares the version in `metadata.lua` with the registry's version, and it leaves a source build alone until a newer release is published.

To work on the plugin itself, see [development.md](development.md).
