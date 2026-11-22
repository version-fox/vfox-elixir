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

--- Returns the versions that `vfox search elixir` lists: the releases, or with the
--- argument hex (`vfox search elixir hex`) the builds of hex.pm. vfox keeps the
--- result per argument, so each list has its own cache entry and one list never
--- shows for the other. VFOX_ELIXIR_MIRROR does not choose the list; it only
--- affects the install.
--- @param ctx table ctx.args holds the words after the plugin name
--- @return table Descriptions of available versions and accompanying tool descriptions
function PLUGIN:Available(ctx)
    local args = ctx.args or {}
    if #args > 1 then
        error("vfox search elixir takes one argument at most: hex, for the hex.pm builds")
    end
    local choice = args[1]
    if choice == "hex" then
        elixirUtils.check_hex_mirror_platform()
        return elixirUtils.get_hex_prebuild_versions()
    end
    if choice ~= nil then
        error('unknown argument "' .. choice .. '": vfox search elixir takes hex, for the hex.pm builds, or nothing')
    end
    if elixirUtils.use_hex_mirror() then
        print("VFOX_ELIXIR_MIRROR=hex does not change this list. For the hex.pm builds, run: vfox search elixir hex")
    end
    return elixirUtils.get_release_versions()
end
