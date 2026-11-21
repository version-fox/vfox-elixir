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

local plugin = test.load({ os = "linux", arch = "amd64", http = answer })
local TAG = "https://github.com/elixir-lang/elixir/releases/tag/"

local function check(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

-- A release that exists is built from its source tarball.
answers[TAG .. "v1.16.2"] = { status_code = 200, body = "" }
local result = plugin:PreInstall({ version = "1.16.2" })
check(result.version, "1.16.2", "version")
check(result.url, "https://github.com/elixir-lang/elixir/archive/refs/tags/v1.16.2.tar.gz", "tarball")

-- A release-candidate tag keeps its suffix.
answers[TAG .. "v1.20.0-rc.6"] = { status_code = 200, body = "" }
result = plugin:PreInstall({ version = "1.20.0-rc.6" })
check(result.url, "https://github.com/elixir-lang/elixir/archive/refs/tags/v1.20.0-rc.6.tar.gz", "rc tarball")

-- A version without a release is refused, and a network error is told apart.
local ok, err = pcall(function()
    plugin:PreInstall({ version = "9.9.9" })
end)
assert(not ok and tostring(err):find("was not found", 1, true), "missing release: " .. tostring(err))

answers[TAG .. "v1.16.3"] = "connection reset"
ok, err = pcall(function()
    plugin:PreInstall({ version = "1.16.3" })
end)
assert(not ok and tostring(err):find("Failed to check", 1, true), "network: " .. tostring(err))

ok, err = pcall(function()
    plugin:PreInstall({})
end)
assert(not ok and tostring(err):find("You must provide a version number", 1, true), "no version: " .. tostring(err))
