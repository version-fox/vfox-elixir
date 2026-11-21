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
    env = { VFOX_ELIXIR_MIRROR = "hex" },
    http = function()
        return { status_code = 200, body = "" }
    end,
})

-- The hex.pm builds are for Unix. Each hook says so instead of downloading
-- a zip that would not run.
local function rejects(fn, message)
    local ok, err = pcall(fn)
    assert(not ok and tostring(err):find(message, 1, true), "expected " .. message .. ", got " .. tostring(err))
end
rejects(function()
    plugin:Available({})
end, "VFOX_ELIXIR_MIRROR=hex is not available on Windows")
rejects(function()
    plugin:PreInstall({ version = "1.16.2-otp-26" })
end, "VFOX_ELIXIR_MIRROR=hex is not available on Windows")
