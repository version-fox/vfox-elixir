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

-- Answers keyed by URL: a { status_code, body } table, or a string for a network error.
local answers = {}
local function answer(request)
    local value = answers[request.url]
    if value == nil then
        return { status_code = 404, body = "" }
    end
    if type(value) == "string" then
        return nil, value
    end
    return value
end

-- VFOX_ELIXIR_MIRROR=hex is set. It does not choose the search list, which is
-- chosen by the search argument; it only makes the install use hex.pm.
local plugin = test.load({
    os = "linux",
    arch = "amd64",
    env = { VFOX_ELIXIR_MIRROR = "hex" },
    http = answer,
})

local function check(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

-- The messages a hook prints are captured, so a test can say which of them a
-- hook prints. The test VM shares its globals with the plugin.
local real_print = print
local function printed_by(fn)
    local lines = {}
    print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring((select(i, ...)))
        end
        table.insert(lines, table.concat(parts, "\t"))
    end
    fn()
    print = real_print
    return lines
end

local WARNING = "Warning: this name has no -otp-N suffix"
local function warned(lines)
    for _, line in ipairs(lines) do
        if line:find(WARNING, 1, true) then
            return true
        end
    end
    return false
end

-- The arguments of PostInstall for a build of the name, installed under the SDK path.
local function sdk(version)
    return { sdkInfo = { elixir = { path = "/home/u/.version-fox/cache/elixir/v-" .. version, version = version } } }
end

local RELEASES = "https://fastly.jsdelivr.net/gh/version-fox/vfox-elixir@main/assets/versions.txt"

answers[RELEASES] = { status_code = 200, body = "1.20.5\n" }
-- Nothing goes to standard error: vfox calls the hook without arguments for
-- `vfox install elixir@latest` too, so a hint would show during an install (issue #35).
local stderr_writes = {}
local real_stderr = io.stderr
io.stderr = {
    write = function(_, text)
        table.insert(stderr_writes, text)
    end,
}
local releases = plugin:Available({})
io.stderr = real_stderr
check(#releases, 1, "releases count")
check(releases[1].version, "1.20.5", "release list with the variable set")
-- A field the hook leaves out comes back as "", not nil.
check(releases[1].note, "", "releases carry no hex note")
check(#stderr_writes, 0, "search writes no hint to standard error")

-- A release is served under the v of its tag, a branch under its name.
local release = plugin:PreInstall({ version = "1.16.2-otp-26" })
check(release.url, "https://builds.hex.pm/builds/elixir/v1.16.2-otp-26.zip", "release zip")
check(release.version, "1.16.2-otp-26", "release name")
local branch = plugin:PreInstall({ version = "main-otp-26" })
check(branch.url, "https://builds.hex.pm/builds/elixir/main-otp-26.zip", "branch zip")

-- A name without an OTP suffix still installs (issue #28). Its warning comes from
-- PostInstall, once the build is downloaded, so PreInstall prints none (issue #35).
local unnamed
local before_download = printed_by(function()
    unnamed = plugin:PreInstall({ version = "1.20.5" })
end)
check(unnamed.url, "https://builds.hex.pm/builds/elixir/v1.20.5.zip", "unnamed zip")
check(warned(before_download), false, "no warning before the download")

-- A name that hex.pm does not have gets no warning either: the download fails, and
-- vfox reports that (issue #35).
check(
    warned(printed_by(function()
        plugin:PreInstall({ version = "9.9.9" })
    end)),
    false,
    "missing name: no warning"
)

-- latest resolves to a release line, which hex.pm does not build: the install
-- stops before the download, and says so (issue #27).
local ok, err = pcall(function()
    plugin:PreInstall({ version = "1.20-latest" })
end)
assert(not ok and tostring(err):find("has no pre-built build on hex.pm", 1, true), "latest: " .. tostring(err))

-- A prebuilt zip needs no build: PostInstall returns without running a shell. It
-- prints the warning for a name without an OTP suffix, now that the zip is there.
check(
    warned(printed_by(function()
        plugin:PostInstall(sdk("1.20.5"))
    end)),
    true,
    "unnamed build: warning after the download"
)
check(
    warned(printed_by(function()
        plugin:PostInstall(sdk("1.16.2-otp-26"))
    end)),
    false,
    "named build: no warning"
)
