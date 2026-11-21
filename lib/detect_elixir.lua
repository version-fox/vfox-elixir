-- Copyright 2026 vfox-elixir contributors
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--   http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

--- Finds Elixir installations that are already on the machine and that vfox
--- did not install, for `vfox link --detect elixir`. Each result is
--- { version, path, note }: the version is the name it is linked under, and the
--- path is the installation root, the directory that holds bin/ and lib/.
local platform = require("platform")

local detect = {}

--- The launcher of an installation root: bin/elixir, or bin\elixir.bat on Windows.
local function launcher(root)
    if platform.is_windows() then
        return platform.child(root, "bin", "elixir.bat")
    end
    return platform.child(root, "bin", "elixir")
end

--- Returns the installation root at path, or nil. A Homebrew keg keeps the
--- files of Elixir under libexec (opt/elixir/libexec/bin/elixir), so libexec is
--- looked at first.
function detect.installation_root(path)
    if path == nil or path == "" then
        return nil
    end
    for _, root in ipairs({ platform.child(path, "libexec"), path }) do
        if platform.file_exists(launcher(root)) then
            return root
        end
    end
    return nil
end

--- Returns the version an installation root carries, or nil: its VERSION file,
--- else the vsn of lib/elixir/ebin/elixir.app, which Debian and Ubuntu ship
--- without a VERSION file.
function detect.version_of(root)
    local version = platform.read_file(platform.child(root, "VERSION"))
    if version ~= nil then
        version = platform.trim(version:match("[^\r\n]+") or "")
    end
    if version == nil or version == "" then
        local app = platform.read_file(platform.child(root, "lib", "elixir", "ebin", "elixir.app"))
        version = app and app:match('{%s*vsn%s*,%s*"([^"]*)"%s*}')
    end
    if version == nil or version == "" then
        return nil
    end
    return version
end

--- Returns true for a name `vfox link` accepts: it starts with a letter or a
--- digit, continues with letters, digits and . _ + -, and is not "latest"
--- (vfox's ValidVersionName).
local function valid_name(name)
    return name ~= nil and name ~= "latest" and name:match("^%w[%w%.%-%+_]*$") ~= nil
end

--- Compares paths the way the platform does: forward slashes, no trailing
--- slash, and case-insensitive on Windows.
local function normalize(path)
    local value = path:gsub("\\", "/"):gsub("/+$", "")
    if platform.is_windows() then
        value = value:lower()
    end
    return value
end

--- Returns true when path is dir itself or lies under it.
local function under(path, dir)
    local p, d = normalize(path), normalize(dir)
    return p == d or p:sub(1, #d + 1) == d .. "/"
end

--- Paths vfox manages are never reported: the cache of a vfox install under
--- its default home (.version-fox, or .vfox), and anything under VFOX_HOME.
local function is_vfox_managed(path)
    local p = path:gsub("\\", "/"):lower()
    if p:find("/.version-fox/", 1, true) or p:find("/.vfox/", 1, true) then
        return true
    end
    if p:match("/%.version%-fox$") or p:match("/%.vfox$") then
        return true
    end
    local vfox_home = platform.env("VFOX_HOME")
    return vfox_home ~= nil and under(path, vfox_home)
end

--- A place to look. kind "home": the path is an installation root itself.
--- kind "children": installations sit directly under the path. dir_names says
--- the version is the directory's name, as asdf and mise name theirs.
local function place(path, note, kind, dir_names)
    return { path = path, note = note, kind = kind, dir_names = dir_names }
end

local function unix_places(home)
    local mise = platform.env("MISE_DATA_DIR") or platform.child(home, ".local", "share", "mise")
    return {
        place(platform.child(home, ".asdf", "installs", "elixir"), "installed by asdf", "children", true),
        place(platform.child(mise, "installs", "elixir"), "installed by mise", "children", true),
        place(platform.child(home, ".linuxbrew", "opt"), "installed by Homebrew", "children", false),
        place("/home/linuxbrew/.linuxbrew/opt", "installed by Homebrew", "children", false),
        place("/opt/homebrew/opt", "installed by Homebrew", "children", false),
        place("/usr/local/opt", "installed by Homebrew", "children", false),
        place("/usr/lib/elixir", "system Elixir", "home", false),
        place("/usr/local/lib/elixir", "system Elixir", "home", false),
        place("/usr/local", "system Elixir", "children", false),
        place("/opt", "system Elixir", "children", false),
    }
end

local function windows_places(userprofile)
    local localappdata = platform.env("LOCALAPPDATA") or platform.child(userprofile, "AppData", "Local")
    local programfiles = platform.env("ProgramFiles") or "C:\\Program Files"
    local places = {
        place(platform.child(userprofile, "scoop", "apps", "elixir"), "installed by Scoop", "children", false),
        place(platform.child(localappdata, "mise", "installs", "elixir"), "installed by mise", "children", true),
        place(platform.child(programfiles, "Elixir"), "system Elixir", "home", false),
        place(platform.child(localappdata, "Programs", "Elixir"), "system Elixir", "home", false),
    }
    local programfiles_x86 = platform.env("ProgramFiles(x86)")
    if programfiles_x86 then
        table.insert(places, place(platform.child(programfiles_x86, "Elixir"), "system Elixir", "home", false))
    end
    return places
end

--- The installation roots that `elixir` resolves to on PATH, found by where
--- on Windows and command -v elsewhere. A symbolic link is followed, so
--- /usr/bin/elixir reaches /usr/lib/elixir.
local function path_homes()
    local homes = {}
    if platform.is_windows() then
        for _, found in ipairs(platform.lines("where elixir 2>nul")) do
            local home = platform.dirname(platform.dirname(found) or "")
            if home then
                table.insert(homes, home)
            end
        end
        return homes
    end
    local found = platform.first_line("command -v elixir 2>/dev/null")
    if found and found:sub(1, 1) == "/" then
        local real = platform.first_line("readlink -f " .. platform.shell_quote(found) .. " 2>/dev/null") or found
        local home = platform.dirname(platform.dirname(real) or "")
        if home then
            table.insert(homes, home)
        end
    end
    return homes
end

--- Finds every Elixir installation the places lead to. The first place that
--- names a version wins, so asdf's and mise's names come before the others. An
--- installation is listed once, and one version once. The result is sorted by
--- version, then by path.
function detect.find_all()
    local home
    if platform.is_windows() then
        home = platform.env("USERPROFILE") or platform.env("HOME") or ""
    else
        home = platform.env("HOME") or ""
    end

    local places
    if platform.is_windows() then
        places = windows_places(home)
    else
        places = unix_places(home)
    end

    local found = {}
    local seen_roots, seen_versions = {}, {}
    local function consider(path, note, dir_names)
        if path == nil or path == "" or is_vfox_managed(path) then
            return
        end
        local root = detect.installation_root(path)
        if root == nil or is_vfox_managed(root) then
            return
        end
        local key = normalize(root)
        if seen_roots[key] then
            return
        end
        seen_roots[key] = true
        local version = detect.version_of(root)
        if version == nil then
            return
        end
        if dir_names then
            version = platform.basename(path)
        end
        if not valid_name(version) or seen_versions[version] then
            return
        end
        seen_versions[version] = true
        table.insert(found, { version = version, path = root, note = note })
    end

    for _, place_item in ipairs(places) do
        if place_item.kind == "home" then
            consider(place_item.path, place_item.note, place_item.dir_names)
        else
            for _, child in ipairs(platform.list_children(place_item.path)) do
                consider(child, place_item.note, place_item.dir_names)
            end
        end
    end
    for _, path in ipairs(path_homes()) do
        consider(path, "found on PATH", false)
    end

    table.sort(found, function(a, b)
        if a.version ~= b.version then
            return a.version < b.version
        end
        return a.path < b.path
    end)
    return found
end

return detect
