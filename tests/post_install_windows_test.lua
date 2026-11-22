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

local plugin = test.load({
    os = "windows",
    arch = "amd64",
    env = { USERPROFILE = "C:\\Users\\u" },
})

-- The download succeeds without a network, and os.execute returns 3, as a failed
-- installer would. The stubs are set after test.load, which sets up the modules.
-- The commands go into a table, which the closure can keep writing to.
local commands = {}
local http = require("http")
http.download_file = function(request, path)
    return nil
end
os.execute = function(command)
    table.insert(commands, command)
    return 3
end

-- A failed installer stops the install with a message that names no exit code:
-- the value of os.execute is not the installer's exit status (issue #37).
local ok, err = pcall(function()
    plugin:PostInstall({
        sdkInfo = {
            elixir = {
                path = "C:\\Users\\u\\cache\\elixir\\v-1.19.5-elixir-otp-26\\elixir-1.19.5-elixir-otp-26",
                version = "1.19.5-elixir-otp-26",
            },
        },
    })
end)
assert(not ok and tostring(err):find("Elixir installer failed", 1, true), "failing installer: " .. tostring(err))
assert(not tostring(err):find("exit code", 1, true), "the message names an exit code: " .. tostring(err))
assert(#commands == 1 and commands[1]:find('" /S /D=', 1, true), "the installer runs silently once")
