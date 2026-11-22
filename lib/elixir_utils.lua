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

--- What the hooks share: the version lists, the names and URLs of the three
--- ways to install Elixir (source, hex.pm builds and the Windows installer),
--- the commands that build or install it, and the search for Erlang/OTP.
local http = require("http")
local platform = require("platform")

local elixir_utils = {}

local GITHUB_ELIXIR = "https://github.com/elixir-lang/elixir/"
local VERSION_LISTS = "https://fastly.jsdelivr.net/gh/version-fox/vfox-elixir@main/assets/"
local HEX_BUILDS = "https://builds.hex.pm/builds/elixir/"
local ERLANG_DOCS = "https://github.com/version-fox/vfox-elixir/blob/main/docs/erlang.md"

--- Returns true when VFOX_ELIXIR_MIRROR asks for the prebuilt builds of hex.pm.
function elixir_utils.use_hex_mirror()
    return os.getenv("VFOX_ELIXIR_MIRROR") == "hex"
end

--- Fails when the hex.pm builds are asked for on Windows, by VFOX_ELIXIR_MIRROR=hex
--- or by `vfox search elixir hex`. Those builds are for Unix, and the Windows
--- installer is the only Windows install.
function elixir_utils.check_hex_mirror_platform()
    if platform.is_windows() then
        error(
            "The hex.pm builds (VFOX_ELIXIR_MIRROR=hex, or vfox search elixir hex) are not available on Windows: "
                .. "they are built for Unix. Install from the official installer, for example "
                .. "vfox install elixir@1.16.2-elixir-otp-26 (see vfox search elixir)."
        )
    end
end

--- Fetches a URL and returns its body. A network error, a status other than
--- 200, an empty body or an HTML page stops the hook with a message that names
--- the address.
function elixir_utils.fetch(url, what)
    local resp, err = http.get({ url = url })
    if err ~= nil or resp == nil then
        error(
            "Failed to fetch "
                .. what
                .. " from "
                .. url
                .. ": "
                .. tostring(err or "no response")
                .. ". Please check your network connection."
        )
    end
    if resp.status_code ~= 200 then
        error("Failed to fetch " .. what .. " from " .. url .. ": HTTP status " .. tostring(resp.status_code) .. ".")
    end
    -- An empty body, or an HTML page that a server or a proxy sends in place of
    -- the list, is not a list of versions. It is neither listed nor cached.
    local body = resp.body or ""
    local lower = body:lower()
    if platform.trim(body) == "" or lower:find("<!doctype", 1, true) or lower:find("<html", 1, true) then
        error(
            "Failed to fetch "
                .. what
                .. " from "
                .. url
                .. ": the response is not a list of versions. Check your network connection and proxy settings."
        )
    end
    return body
end

--- Turns a text with one version per line into vfox's list of versions. The
--- first word of each line is the version; note, when given, goes with each.
local function version_list(body, note)
    local result = {}
    for line in string.gmatch(body, "[^\r\n]+") do
        local name = string.match(line, "^%s*(%S+)")
        if name then
            local entry = { version = name }
            if note then
                entry.note = note
            end
            table.insert(result, entry)
        end
    end
    return result
end

--- Returns the versions of the official releases: the source list on Linux
--- and macOS, the installer list on Windows.
function elixir_utils.get_release_versions()
    if platform.is_windows() then
        local url = VERSION_LISTS .. "versions_win.txt"
        return version_list(elixir_utils.fetch(url, "the Windows Elixir versions"))
    end
    local url = VERSION_LISTS .. "versions.txt"
    return version_list(elixir_utils.fetch(url, "the Elixir versions"))
end

--- Returns the prebuilt builds of hex.pm. A release is listed without the v
--- of its tag (v1.16.2-otp-26 is 1.16.2-otp-26), a branch keeps its name
--- (main-otp-26).
function elixir_utils.get_hex_prebuild_versions()
    local url = HEX_BUILDS .. "builds.txt"
    local result = {}
    for _, entry in ipairs(version_list(elixir_utils.fetch(url, "the hex.pm builds"), "pre-built from hex.pm")) do
        entry.version = string.match(entry.version, "^v(%d.*)$") or entry.version
        table.insert(result, entry)
    end
    return result
end

--- Returns the address of the prebuilt zip of a version. A release is served
--- under the v of its tag (v1.16.2-otp-26.zip), a branch under its name.
function elixir_utils.get_hex_prebuild_url(version)
    local name = version
    if string.match(version, "^%d") then
        name = "v" .. version
    end
    return HEX_BUILDS .. name .. ".zip"
end

--- Fails unless the Elixir release exists on GitHub. A network error is told
--- apart from a release that is not there.
function elixir_utils.check_version_existence(version)
    local url = GITHUB_ELIXIR .. "releases/tag/v" .. version
    print("Check Elixir release version existence: " .. url)
    local resp, err = http.get({ url = url })
    if err ~= nil or resp == nil then
        error(
            "Failed to check "
                .. url
                .. ": "
                .. tostring(err or "no response")
                .. ". Please check your network connection."
        )
    end
    if resp.status_code ~= 200 then
        error(
            "Elixir "
                .. version
                .. " was not found. Please confirm that the version exists: https://github.com/elixir-lang/elixir/releases"
        )
    end
end

--- Splits a Windows version name into the release tag and the installer's file
--- name on GitHub: 1.16.2-elixir-otp-26 is release 1.16.2 and elixir-otp-26.exe.
--- The split is on the last -elixir-otp-, so a release candidate keeps its
--- suffix: 1.19.0-rc.2-elixir-otp-28 is release 1.19.0-rc.2. Returns nil for any
--- other name.
function elixir_utils.windows_installer_parts(version)
    local release, otp = string.match(version, "^(%d.*)%-elixir%-otp%-(%d+)$")
    if release == nil then
        return nil
    end
    return release, "elixir-otp-" .. otp .. ".exe"
end

--- Fails unless the version names a Windows installer, as the list of
--- Windows versions does.
function elixir_utils.check_windows_version(version)
    if elixir_utils.windows_installer_parts(version) == nil then
        error(
            'On Windows Elixir comes from the official installer, so name the version it ships with, such as 1.16.2-elixir-otp-26; "'
                .. version
                .. '" does not match. See vfox search elixir for the names.'
        )
    end
end

--- Returns the address of the installer of a Windows version.
function elixir_utils.windows_download_url(version)
    local release, installer = elixir_utils.windows_installer_parts(version)
    if release == nil then
        error("Not a Windows Elixir version: " .. version)
    end
    return GITHUB_ELIXIR .. "releases/download/v" .. release .. "/" .. installer
end

--- The command that runs the installer silently into dir, the SDK's install
--- path. The installer's path is quoted, because the plugin directory can hold
--- spaces (a VFOX_HOME under C:\Users\John Doe). /D= comes last and unquoted,
--- as NSIS requires.
function elixir_utils.windows_install_command(installer, dir)
    return '"' .. installer .. '" /S /D=' .. dir
end

--- Downloads the installer of a Windows version, runs it silently into dir and
--- removes the installer afterwards.
function elixir_utils.windows_install_exe(version, dir)
    elixir_utils.check_windows_version(version)
    local url = elixir_utils.windows_download_url(version)
    local download_dir = RUNTIME.pluginDirPath or os.getenv("TEMP") or "."
    local installer = platform.join(download_dir, version .. ".exe")

    print("Downloading installer...")
    print("from:\t" .. url)
    print("to:\t" .. installer)
    local err = http.download_file({ url = url }, installer)
    if err ~= nil then
        error("Downloading the installer failed: " .. url .. ": " .. tostring(err))
    end

    local command = elixir_utils.windows_install_command(installer, dir)
    print("install cmd: " .. command)
    local status = os.execute(command)
    os.remove(installer)
    if status ~= 0 then
        error(
            "Elixir installer failed with exit code "
                .. tostring(status)
                .. ". Check the output above; see https://github.com/version-fox/vfox-elixir/blob/main/docs/troubleshooting.md"
        )
    end
end

--- Returns the cache directory vfox keeps the SDKs in. An SDK is installed at
--- <cache>/<plugin>/v-<version>/<plugin>-<version>, so the cache is the nearest
--- ancestor named cache. Returns nil when there is none.
function elixir_utils.cache_root(sdk_path)
    local current = sdk_path
    while current ~= nil and current ~= "" do
        if platform.basename(current) == "cache" then
            return current
        end
        local parent = platform.dirname(current)
        if parent == nil or parent == current then
            return nil
        end
        current = parent
    end
    return nil
end

--- The erlc files under root, sorted, without those in bootstrap/. OTP's
--- bootstrap compiler runs without the make module, which Elixir's make needs,
--- so it is never used. Symbolic links count: a source build of vfox-erlang
--- puts its erl and erlc in release/bin as links.
local function erlc_candidates(root)
    local result = {}
    local command = "find " .. platform.shell_quote(root) .. " -maxdepth 6 -name erlc 2>/dev/null | sort"
    for _, path in ipairs(platform.lines(command)) do
        if not path:find("/bootstrap/", 1, true) then
            table.insert(result, path)
        end
    end
    return result
end

--- Returns the directory of an erlc installed under root, or nil. vfox-erlang
--- runs erl from release/bin for a source build, and a prebuilt install keeps
--- it in bin or lib/erlang/bin, so those come in that order. Where several
--- match, the last one in sorted order is taken, which is the highest version.
local function erlc_under(root)
    local candidates = erlc_candidates(root)
    for _, suffix in ipairs({ "/release/bin/erlc", "/bin/erlc", "/lib/erlang/bin/erlc" }) do
        local chosen
        for _, path in ipairs(candidates) do
            if path:sub(-#suffix) == suffix then
                chosen = path
            end
        end
        if chosen then
            return platform.dirname(chosen)
        end
    end
    return nil
end

--- Returns the directory that holds erlc, or nil. It looks on PATH first, then
--- in the Erlang/OTP that vfox installed (cache/erlang, see cache_root), then in
--- mise's installs. Windows builds Elixir from its installer, which needs no
--- erlc, so nothing is searched there.
function elixir_utils.find_erlang_bin(cache)
    if platform.is_windows() then
        return nil
    end

    local found = platform.first_line("command -v erlc 2>/dev/null")
    if found and found:sub(1, 1) == "/" then
        return platform.dirname(found)
    end

    if cache then
        local bin = erlc_under(platform.join(cache, "erlang"))
        if bin then
            return bin
        end
    end

    local mise = platform.env("MISE_DATA_DIR")
    if mise == nil and platform.env("HOME") then
        mise = platform.child(platform.env("HOME"), ".local", "share", "mise")
    end
    if mise then
        return erlc_under(platform.child(mise, "installs", "erlang"))
    end
    return nil
end

--- Returns the directory of erlc, or fails: Elixir is compiled with Erlang/OTP.
function elixir_utils.require_erlang_bin(cache)
    local bin = elixir_utils.find_erlang_bin(cache)
    if bin == nil then
        error(
            "Erlang/OTP was not found, and Elixir is compiled with it. Install it first, for example "
                .. "vfox install erlang@26.2.3, or put erlc on PATH. See "
                .. ERLANG_DOCS
        )
    end
    return bin
end

--- The shell command that builds Elixir in source_dir with make. When erlang_bin
--- is given it is put first on PATH, so the build uses that Erlang/OTP.
function elixir_utils.build_command(source_dir, erlang_bin)
    local command = "cd " .. platform.shell_quote(source_dir) .. " && "
    if erlang_bin then
        command = command .. "PATH=" .. platform.shell_quote(erlang_bin) .. ':"$PATH" '
    end
    return command .. "make"
end

return elixir_utils
