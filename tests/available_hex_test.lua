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

-- The search argument selects the hex.pm list, with no environment variable set.
local plugin = test.load({ os = "linux", arch = "amd64", http = answer })

local function check(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local BUILDS = "https://builds.hex.pm/builds/elixir/builds.txt"

-- The builds of hex.pm: the first word of each line is the name. A release
-- loses its v, a branch keeps its name.
answers[BUILDS] = {
    status_code = 200,
    body = table.concat({
        "main 60200fefaaee0d9773a03fe84d6747f73b47de6a 2026-11-21T11:42:25Z ba11",
        "main-otp-26 8914dcdcbb9841ff07b786724671c58d8ccacc55 2026-03-09T19:38:40Z 187f",
        "v1.16.2-otp-26 41f6ee3f2e605f7066b23d96362e3b0c620c565b 2024-03-10T11:08:31Z 04ba",
        "v1.20.5 4a28692668bef879029291b7ff329a84a1f933bb 2026-10-29T19:43:19Z d059",
        "",
    }, "\n"),
}
local list = plugin:Available({ args = { "hex" } })
check(#list, 4, "count")
check(list[1].version, "main", "branch")
check(list[1].note, "pre-built from hex.pm", "note")
check(list[2].version, "main-otp-26", "branch with OTP")
check(list[3].version, "1.16.2-otp-26", "release with OTP")
check(list[4].version, "1.20.5", "release")

-- The checks that expect an error come last in the file.
-- An empty builds.txt is not a list either: the search stops, and lists nothing.
answers[BUILDS] = { status_code = 200, body = "\n" }
local ok, err = pcall(function()
    plugin:Available({ args = { "hex" } })
end)
assert(not ok and tostring(err):find("not a list of versions", 1, true), "empty builds.txt: " .. tostring(err))

-- Only hex is a search argument, and only one of them.
ok, err = pcall(function()
    plugin:Available({ args = { "1.16.2" } })
end)
assert(not ok and tostring(err):find("unknown argument", 1, true), "unknown argument: " .. tostring(err))
ok, err = pcall(function()
    plugin:Available({ args = { "hex", "hex" } })
end)
assert(not ok and tostring(err):find("at most", 1, true), "two arguments: " .. tostring(err))
