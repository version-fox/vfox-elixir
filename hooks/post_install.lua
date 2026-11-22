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

--- Extension point, called after PreInstall, can perform additional operations,
--- such as file operations for the SDK installation directory or compile source code.
--- Source builds run make in the SDK directory, with the Erlang/OTP that
--- erlc is found in first on PATH. The Windows installer is run into the
--- SDK directory. A prebuilt hex.pm zip needs nothing more.
--- @param ctx table ctx.sdkInfo['elixir'] holds the install path and version
function PLUGIN:PostInstall(ctx)
    local sdkInfo = ctx.sdkInfo["elixir"]
    local path = sdkInfo.path

    if elixirUtils.use_hex_mirror() then
        return
    end

    if platform.is_windows() then
        return elixirUtils.windows_install_exe(sdkInfo.version, path)
    end

    elixirUtils.check_build_path(path)
    local erlang_bin = elixirUtils.require_erlang_bin(elixirUtils.cache_root(path))
    local status = os.execute(elixirUtils.build_command(path, erlang_bin))
    if status ~= 0 then
        error(
            "Elixir build failed with exit code "
                .. tostring(status)
                .. ". Check the output above; see https://github.com/version-fox/vfox-elixir/blob/main/docs/troubleshooting.md"
        )
    end
end
