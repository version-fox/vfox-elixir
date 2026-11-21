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
local plugin = test.load({ os = "windows", arch = "amd64" })

local env = plugin:EnvKeys({ path = "C:\\Users\\John Doe\\.version-fox\\cache\\elixir\\v-1.16.2" })
assert(#env == 1, "one variable")
assert(env[1].key == "PATH", "PATH, got " .. tostring(env[1].key))
assert(
    env[1].value == "C:\\Users\\John Doe\\.version-fox\\cache\\elixir\\v-1.16.2\\bin",
    "bin under the install, got " .. tostring(env[1].value)
)
