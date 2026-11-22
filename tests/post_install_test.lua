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

-- The build itself runs in tests/post_install_layouts.lua, which can run a
-- shell. Here the Erlang/OTP lookup finds nothing, and PostInstall must say so
-- before it tries to build.
local test = require("vfox.test")
local plugin = test.load({ os = "linux", arch = "amd64", env = { HOME = "/home/u" } })

io.popen = function(command, mode)
    return {
        read = function()
            return nil
        end,
        close = function()
            return true
        end,
    }
end

local ok, err = pcall(function()
    plugin:PostInstall({
        sdkInfo = { elixir = { path = "/home/u/.version-fox/cache/elixir/v-1.16.2/elixir-1.16.2", version = "1.16.2" } },
    })
end)
assert(not ok and tostring(err):find("Erlang/OTP was not found", 1, true), "no Erlang: " .. tostring(err))

-- A path with a space is refused before the Erlang/OTP lookup, which runs a
-- shell, because Elixir's Makefile cannot take it (issue #31).
ok, err = pcall(function()
    plugin:PostInstall({
        sdkInfo = { elixir = { path = "/home/u/vfox home/cache/elixir/v-1.16.2/elixir-1.16.2", version = "1.16.2" } },
    })
end)
assert(not ok and tostring(err):find("cannot run in", 1, true), "space in path: " .. tostring(err))
