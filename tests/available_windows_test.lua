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

local plugin = test.load({ os = "windows", arch = "amd64", http = answer })

local function check(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

-- Windows lists the installers: the releases with the OTP release they ship for.
answers["https://fastly.jsdelivr.net/gh/version-fox/vfox-elixir@main/assets/versions_win.txt"] = {
    status_code = 200,
    body = "1.19.0-rc.2-elixir-otp-28\n1.19.5-elixir-otp-26\n",
}
local list = plugin:Available({})
check(#list, 2, "count")
check(list[1].version, "1.19.0-rc.2-elixir-otp-28", "release candidate")

-- The installer is the version: vfox does not download it, PostInstall runs it.
-- A field the hook leaves out comes back as "", not nil.
local installer = plugin:PreInstall({ version = "1.19.0-rc.2-elixir-otp-28" })
check(installer.version, "1.19.0-rc.2-elixir-otp-28", "installer name")
check(installer.url, "", "no download named")

-- A Unix-style version does not name an installer; the error says so.
local ok, err = pcall(function()
    plugin:PreInstall({ version = "1.16.2" })
end)
assert(not ok and tostring(err):find("does not match", 1, true), "bare version: " .. tostring(err))
