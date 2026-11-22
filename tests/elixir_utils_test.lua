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

local test = require("vfox.test")

-- Command output by exact command line; a command not listed prints nothing.
local commands = {}
io.popen = function(command, mode)
    local lines = commands[command] or {}
    local index = 0
    -- The handle as io.popen gives it on Windows in vfox 1.1.0: read returns one
    -- line per call, and nil after the last one. There is no lines method.
    return {
        read = function()
            index = index + 1
            return lines[index]
        end,
        close = function()
            return true
        end,
    }
end

local plugin = test.load({
    os = "linux",
    arch = "amd64",
    env = { HOME = "/home/u" },
})
local elixir_utils = require("elixir_utils")

local function check(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

-- The Windows installer names: the split is on the last -elixir-otp-, so a
-- release candidate keeps its suffix.
local release, installer = elixir_utils.windows_installer_parts("1.16.2-elixir-otp-26")
check(release, "1.16.2", "release")
check(installer, "elixir-otp-26.exe", "installer")
release, installer = elixir_utils.windows_installer_parts("1.19.0-rc.2-elixir-otp-28")
check(release, "1.19.0-rc.2", "release candidate")
check(installer, "elixir-otp-28.exe", "candidate installer")
check(elixir_utils.windows_installer_parts("1.16.2"), nil, "no OTP release")
check(elixir_utils.windows_installer_parts("main-otp-26"), nil, "not a release")
check(
    elixir_utils.windows_download_url("1.19.0-rc.2-elixir-otp-28"),
    "https://github.com/elixir-lang/elixir/releases/download/v1.19.0-rc.2/elixir-otp-28.exe",
    "download URL"
)

-- The installer path is quoted, the /D= directory is not.
check(
    elixir_utils.windows_install_command(
        "C:\\Users\\John Doe\\plugin\\1.16.2.exe",
        "C:\\Users\\John Doe\\cache\\elixir"
    ),
    '"C:\\Users\\John Doe\\plugin\\1.16.2.exe" /S /D=C:\\Users\\John Doe\\cache\\elixir',
    "installer command"
)

-- The build runs in the source directory, with the given Erlang/OTP first on PATH.
check(
    elixir_utils.build_command("/home/u/my elixir/v-1.16.2", "/opt/erl bin"),
    "cd '/home/u/my elixir/v-1.16.2' && PATH='/opt/erl bin':\"$PATH\" make",
    "build with Erlang"
)
check(elixir_utils.build_command("/x", nil), "cd '/x' && make", "build without Erlang")
check(elixir_utils.build_command("/x/it's", nil), "cd '/x/it'\\''s' && make", "quoted quote")

-- vfox installs an SDK at <cache>/<plugin>/v-<version>/<plugin>-<version>, so
-- the cache is the nearest ancestor named cache.
check(
    elixir_utils.cache_root("/home/u/.version-fox/cache/elixir/v-1.16.2/elixir-1.16.2"),
    "/home/u/.version-fox/cache",
    "cache root"
)
check(
    elixir_utils.cache_root("/srv/cache/vfox/cache/elixir/v-1.16.2/elixir-1.16.2"),
    "/srv/cache/vfox/cache",
    "nearest cache"
)
check(elixir_utils.cache_root("/opt/elixir/v-1.16.2/elixir-1.16.2"), nil, "no cache")

-- The hex.pm zip of a release carries the v of its tag, a branch does not.
check(
    elixir_utils.get_hex_prebuild_url("1.16.2-otp-26"),
    "https://builds.hex.pm/builds/elixir/v1.16.2-otp-26.zip",
    "release zip"
)
check(
    elixir_utils.get_hex_prebuild_url("main-otp-26"),
    "https://builds.hex.pm/builds/elixir/main-otp-26.zip",
    "branch zip"
)

-- erlc is looked for on PATH first, then in vfox's Erlang/OTP, then in mise.
commands["command -v erlc 2>/dev/null"] = { "/usr/local/bin/erlc" }
check(elixir_utils.find_erlang_bin("/home/u/.version-fox/cache"), "/usr/local/bin", "on PATH")

-- In vfox's cache a source build's release/bin wins over bootstrap/, whatever
-- the order of the list: OTP's bootstrap erl has no make module.
local cache_find = "find '/home/u/.version-fox/cache/erlang' -maxdepth 6 -name erlc 2>/dev/null | sort"
local otp_root = "/home/u/.version-fox/cache/erlang/v-26.2.3/erlang-26.2.3"
commands["command -v erlc 2>/dev/null"] = {}
commands[cache_find] = {
    otp_root .. "/bin/erlc",
    otp_root .. "/bootstrap/bin/erlc",
    otp_root .. "/release/bin/erlc",
}
check(
    elixir_utils.find_erlang_bin("/home/u/.version-fox/cache"),
    otp_root .. "/release/bin",
    "release/bin of a source build"
)

-- Without release/bin, a prebuilt install's bin is used, and a bootstrap alone is not.
commands[cache_find] = {
    "/home/u/.version-fox/cache/erlang/v-25.3.2/erlang-25.3.2/bootstrap/bin/erlc",
    "/home/u/.version-fox/cache/erlang/v-25.3.2/erlang-25.3.2/bin/erlc",
}
check(
    elixir_utils.find_erlang_bin("/home/u/.version-fox/cache"),
    "/home/u/.version-fox/cache/erlang/v-25.3.2/erlang-25.3.2/bin",
    "bin of a prebuilt install"
)

-- Where the cache holds only a bootstrap, mise's installs are searched.
local mise_find = "find '/home/u/.local/share/mise/installs/erlang' -maxdepth 6 -name erlc 2>/dev/null | sort"
commands[cache_find] = { otp_root .. "/bootstrap/bin/erlc" }
commands[mise_find] = { "/home/u/.local/share/mise/installs/erlang/26.2.3/bin/erlc" }
check(
    elixir_utils.find_erlang_bin("/home/u/.version-fox/cache"),
    "/home/u/.local/share/mise/installs/erlang/26.2.3/bin",
    "in mise"
)

commands[mise_find] = {}
check(elixir_utils.find_erlang_bin("/home/u/.version-fox/cache"), nil, "not found")

-- Without Erlang/OTP the error says what to install.
local ok, err = pcall(function()
    elixir_utils.require_erlang_bin("/home/u/.version-fox/cache")
end)
assert(not ok and tostring(err):find("vfox install erlang@26.2.3", 1, true), "missing erlang: " .. tostring(err))
