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

local answers = {}
local function answer(request)
    local value = answers[request.url]
    if value == nil then
        return { status_code = 404, body = "" }
    end
    return value
end

local plugin = test.load({
    os = "linux",
    arch = "amd64",
    env = { VFOX_ELIXIR_MIRROR = "hex" },
    http = answer,
})

local function check(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

-- The builds of hex.pm: the first word of each line is the name. A release
-- loses its v, a branch keeps its name.
answers["https://builds.hex.pm/builds/elixir/builds.txt"] = {
    status_code = 200,
    body = table.concat({
        "main 60200fefaaee0d9773a03fe84d6747f73b47de6a 2026-11-21T11:42:25Z ba11",
        "main-otp-26 8914dcdcbb9841ff07b786724671c58d8ccacc55 2026-03-09T19:38:40Z 187f",
        "v1.16.2-otp-26 41f6ee3f2e605f7066b23d96362e3b0c620c565b 2024-03-10T11:08:31Z 04ba",
        "v1.20.5 4a28692668bef879029291b7ff329a84a1f933bb 2026-10-29T19:43:19Z d059",
        "",
    }, "\n"),
}
local list = plugin:Available({})
check(#list, 4, "count")
check(list[1].version, "main", "branch")
check(list[1].note, "pre-built from hex.pm", "note")
check(list[2].version, "main-otp-26", "branch with OTP")
check(list[3].version, "1.16.2-otp-26", "release with OTP")
check(list[4].version, "1.20.5", "release")

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

-- An empty builds.txt is not a list either: the search stops, and lists nothing.
answers["https://builds.hex.pm/builds/elixir/builds.txt"] = { status_code = 200, body = "\n" }
local ok, err = pcall(function()
    plugin:Available({})
end)
assert(not ok and tostring(err):find("not a list of versions", 1, true), "empty builds.txt: " .. tostring(err))
