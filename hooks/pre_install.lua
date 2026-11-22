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

local elixirUtils = require("elixir_utils")
local platform = require("platform")

--- Returns some pre-installed information, such as version number, download address, local files, etc.
--- The source tarball of a release, or the prebuilt zip of hex.pm when
--- VFOX_ELIXIR_MIRROR=hex. On Windows no download is named: PostInstall runs
--- the installer, which vfox cannot download itself.
--- @param ctx table Context information; ctx.version is the version the user typed
--- @return table Version information
function PLUGIN:PreInstall(ctx)
    local elixir_version = ctx.version
    if elixir_version == nil or elixir_version == "" then
        error("You must provide a version number for Elixir, eg: vfox install elixir@1.16.2")
    end

    print("You will install the elixir version is " .. elixir_version)

    if elixirUtils.use_hex_mirror() then
        elixirUtils.check_hex_mirror_platform()
        local otp_release = elixirUtils.check_hex_build(elixir_version)
        local hex_url = elixirUtils.get_hex_prebuild_url(elixir_version)
        print("Download URL: " .. hex_url)
        if otp_release then
            print("This build needs Erlang/OTP " .. otp_release .. ".")
        else
            print(
                "Warning: this name has no -otp-N suffix, so hex.pm does not say which Erlang/OTP the build is for. "
                    .. "If elixir then refuses to run, install a name with -otp-N (see vfox search elixir hex)."
            )
        end
        return {
            version = elixir_version,
            url = hex_url,
        }
    end

    if platform.is_windows() then
        elixirUtils.check_windows_version(elixir_version)
        return {
            version = elixir_version,
        }
    end

    elixirUtils.check_version_existence(elixir_version)
    local download_url = "https://github.com/elixir-lang/elixir/archive/refs/tags/v" .. elixir_version .. ".tar.gz"
    print("Download URL: " .. download_url)
    return {
        version = elixir_version,
        url = download_url,
    }
end
