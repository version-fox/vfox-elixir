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

local RELEASES = "https://fastly.jsdelivr.net/gh/version-fox/vfox-elixir@main/assets/versions.txt"

answers[RELEASES] = { status_code = 200, body = "1.20.5\n" }
local releases = plugin:Available({})
check(#releases, 1, "releases count")
check(releases[1].version, "1.20.5", "release list with the variable set")
-- A field the hook leaves out comes back as "", not nil.
check(releases[1].note, "", "releases carry no hex note")

-- A release is served under the v of its tag, a branch under its name.
local release = plugin:PreInstall({ version = "1.16.2-otp-26" })
check(release.url, "https://builds.hex.pm/builds/elixir/v1.16.2-otp-26.zip", "release zip")
check(release.version, "1.16.2-otp-26", "release name")
local branch = plugin:PreInstall({ version = "main-otp-26" })
check(branch.url, "https://builds.hex.pm/builds/elixir/main-otp-26.zip", "branch zip")

-- A prebuilt zip needs no build: PostInstall returns without running a shell.
plugin:PostInstall({
    sdkInfo = { elixir = { path = "/home/u/.version-fox/cache/elixir/v-1.16.2-otp-26", version = "1.16.2-otp-26" } },
})
