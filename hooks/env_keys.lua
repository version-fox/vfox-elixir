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

--- Each SDK may have different environment variable configurations.
--- This allows plugins to define custom environment variables (including PATH settings)
--- Note: Be sure to distinguish between environment variable settings for different platforms!
--- The same keys serve installs of this plugin and the ones vfox links to, such as
--- an Elixir found by `vfox link --detect elixir`.
--- @param ctx table Context information; ctx.path is the SDK installation directory
function PLUGIN:EnvKeys(ctx)
    local mainPath
    if RUNTIME.osType == "windows" then
        mainPath = ctx.path .. "\\bin"
    else
        mainPath = ctx.path .. "/bin"
    end
    return {
        {
            key = "PATH",
            value = mainPath,
        },
    }
end
