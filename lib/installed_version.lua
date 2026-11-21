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

--- Matches a version the user typed against the names that are installed.
--- Installed names are the release, then the OTP release it was built for when
--- the name carries one: 1.16.2-otp-26 (asdf, mise, hex.pm builds),
--- 1.16.2-elixir-otp-26 (the Windows installer), and plain 1.16.2 (a source build).
local installed_version = {}

--- Returns the OTP release of an installed name that starts with version, as
--- in 1.16.2-otp-26 for 1.16.2, or nil. The comparison is on plain text, so
--- the dots of a version match only themselves.
local function otp_release(name, version)
    local prefix = version .. "-"
    if name:sub(1, #prefix) ~= prefix then
        return nil
    end
    local rest = name:sub(#prefix + 1)
    local otp = rest:match("^otp%-(%d+)$") or rest:match("^elixir%-otp%-(%d+)$")
    return tonumber(otp)
end

--- Returns the installed name vfox should select for a version the user
--- typed, or nil. The name itself wins. Otherwise a release written without
--- its OTP release (1.16.2) selects its newest build that carries one: the
--- highest OTP release, then the name that sorts first.
function installed_version.find(installed, version)
    if installed[version] then
        return version
    end
    local best, best_otp
    for name in pairs(installed) do
        local otp = otp_release(name, version)
        if otp and (best_otp == nil or otp > best_otp or (otp == best_otp and name < best)) then
            best, best_otp = name, otp
        end
    end
    return best
end

return installed_version
