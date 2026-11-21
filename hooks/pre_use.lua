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

local installed_version = require("installed_version")

--- When user invoke `use` command, this function will be called to get the
--- valid version information. A version written without its OTP release
--- (1.16.2) selects the newest installed build of it. One that is not
--- installed is returned as it was typed, and vfox reports it as not installed.
--- @param ctx table Context information
function PLUGIN:PreUse(ctx)
    --- user input version
    local input_version = ctx.version

    --- installed sdks, keyed by their names
    local installed = ctx.installedSdks or {}

    --- return the version information
    return {
        version = installed_version.find(installed, input_version) or input_version,
    }
end
