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
local LIST = "https://fastly.jsdelivr.net/gh/version-fox/vfox-elixir@main/assets/versions.txt"

local function check(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

-- Linux and macOS list the source releases, one per line.
answers[LIST] = { status_code = 200, body = "1.20.5\n1.20.0-rc.6\r\n1.18-latest\n" }
local list = plugin:Available({})
check(#list, 3, "count")
check(list[1].version, "1.20.5", "first")
check(list[2].version, "1.20.0-rc.6", "release candidate")
check(list[3].version, "1.18-latest", "latest")

-- A failed request stops the hook and names the address; the next call works again.
answers[LIST] = { status_code = 503, body = "" }
local ok, err = pcall(function()
    plugin:Available({})
end)
assert(not ok and tostring(err):find("HTTP status 503", 1, true), "503: " .. tostring(err))

-- An error page is not a list of versions, whatever its status: a 404 page
-- stops the hook with its status, and an HTML page or an empty body with
-- status 200 stops it too. Nothing is listed, and nothing is cached (issue #22).
answers[LIST] = {
    status_code = 404,
    body = "<!DOCTYPE HTML>\n<title>Error response</title>\nError code: 404\n",
}
ok, err = pcall(function()
    plugin:Available({})
end)
assert(not ok and tostring(err):find("HTTP status 404", 1, true), "404 page: " .. tostring(err))

answers[LIST] = { status_code = 200, body = "<html><body>Service unavailable</body></html>\n" }
ok, err = pcall(function()
    plugin:Available({})
end)
assert(not ok and tostring(err):find("not a list of versions", 1, true), "200 HTML page: " .. tostring(err))

answers[LIST] = { status_code = 200, body = " \n" }
ok, err = pcall(function()
    plugin:Available({})
end)
assert(not ok and tostring(err):find("not a list of versions", 1, true), "empty body: " .. tostring(err))

answers[LIST] = "connection reset"
ok, err = pcall(function()
    plugin:Available({})
end)
assert(not ok and tostring(err):find("Failed to fetch the Elixir versions", 1, true), "network: " .. tostring(err))
