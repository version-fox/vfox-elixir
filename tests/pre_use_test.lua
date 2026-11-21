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

-- Installed versions as vfox passes them, keyed by name.
local function sdks(names)
    local installed = {}
    for _, name in ipairs(names) do
        installed[name] = { name = "elixir", version = name, path = "/sdks/elixir-" .. name }
    end
    return installed
end

local installed = sdks({ "1.16.2-otp-25", "1.16.2-otp-26", "1.16.2", "1.19.0-rc.2-otp-28", "1.16.20-otp-27" })

local function use(version, sdk_map)
    return plugin:PreUse({ version = version, installedSdks = sdk_map }).version
end

local function check(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

-- A name that is installed is selected as it is.
check(use("1.16.2-otp-25", installed), "1.16.2-otp-25", "exact OTP")
check(use("1.16.2", installed), "1.16.2", "source build")
-- A release without its OTP release selects the newest build of it.
check(use("1.19.0-rc.2", installed), "1.19.0-rc.2-otp-28", "release candidate")
-- Only the release itself matches: 1.16.2 does not select 1.16.20-otp-27.
check(use("1.16.2", sdks({ "1.16.20-otp-27" })), "1.16.2", "not a longer release")
-- A name that is not installed comes back as it was typed, for vfox to report.
check(use("1.99.0", installed), "1.99.0", "not installed")
check(use("1.16.2", nil), "1.16.2", "no installed table")
