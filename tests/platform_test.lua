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
local plugin = test.load({ os = "linux", arch = "amd64" })
local platform = require("platform")

local function check(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

check(platform.join("/a", "b"), "/a/b", "join")
check(platform.join("/a/", "b"), "/a/b", "join keeps one separator")
check(platform.join("", "b"), "", "an empty base stays empty")
check(platform.child("/a", "lib/elixir", "ebin"), "/a/lib/elixir/ebin", "child splits segments")
check(platform.dirname("/usr/bin/elixir"), "/usr/bin", "dirname")
check(platform.dirname("/usr"), nil, "dirname of a top-level name")
check(platform.basename("/a/b/1.16.2-otp-26"), "1.16.2-otp-26", "basename")
check(platform.shell_quote("it's"), "'it'\\''s'", "shell quote")
check(platform.trim("  x \r\n"), "x", "trim")
check(platform.env("VFOX_ELIXIR_NOT_SET_FOR_TESTS"), nil, "unset variable")
