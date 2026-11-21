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
local installed_version = require("installed_version")

local function find(names, version)
    local installed = {}
    for _, name in ipairs(names) do
        installed[name] = true
    end
    return installed_version.find(installed, version)
end

local function check(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

check(find({ "1.16.2-otp-26", "1.16.2-otp-25" }, "1.16.2-otp-26"), "1.16.2-otp-26", "exact")
-- The highest OTP release wins, whatever the order of the names.
check(find({ "1.16.2-otp-25", "1.16.2-otp-26" }, "1.16.2"), "1.16.2-otp-26", "highest OTP")
check(find({ "1.16.2-otp-26", "1.16.2-elixir-otp-27" }, "1.16.2"), "1.16.2-elixir-otp-27", "Windows name")
-- Equal OTP releases are ordered by name, so the choice does not depend on the order of the table.
check(find({ "1.16.2-otp-26", "1.16.2-elixir-otp-26" }, "1.16.2"), "1.16.2-elixir-otp-26", "tie")
-- Plain text comparison: the dots of a version match only themselves.
check(find({ "1.16.2-otp-26" }, "1.16"), nil, "shorter release")
check(find({ "11.0.0-otp-26" }, "1.0.0"), nil, "different digits")
check(find({ "1.16.2-otp-26" }, "1.16.2-otp-2"), nil, "partial OTP")
check(find({ "1.16.2-otp-26" }, "1.16.2-elixir-otp-26"), nil, "other spelling")
check(find({}, "1.16.2"), nil, "nothing installed")
