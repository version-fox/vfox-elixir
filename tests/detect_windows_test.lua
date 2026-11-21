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
local plugin = test.load({
    os = "windows",
    arch = "amd64",
    env = {
        USERPROFILE = "C:\\Users\\John Doe",
        LOCALAPPDATA = "C:\\Users\\John Doe\\AppData\\Local",
        ProgramFiles = "C:\\Program Files",
    },
})
local detect_elixir = require("detect_elixir")

-- A fake filesystem with Windows paths. dirs holds the children of a directory,
-- commands the output of a command.
local files = {}
local dirs = {}
local commands = {}

io.open = function(path, mode)
    local content = files[path]
    if content == nil then
        return nil
    end
    return {
        read = function(_, what)
            if what == "*a" then
                return content
            end
            return nil
        end,
        close = function()
            return true
        end,
    }
end

io.popen = function(command, mode)
    local lines = commands[command]
    if lines == nil then
        local dir = command:match('^dir /b /ad "(.*)" 2>nul$')
        lines = dir and dirs[dir] or {}
    end
    local index = 0
    return {
        lines = function()
            return function()
                index = index + 1
                return lines[index]
            end
        end,
        close = function()
            return true
        end,
    }
end

-- An installer's layout on Windows: the launcher bin\elixir.bat and a VERSION file.
local function install(root, version)
    files[root .. "\\bin\\elixir.bat"] = ""
    files[root .. "\\VERSION"] = version .. "\r\n"
end

local function found(entries)
    local lines = {}
    for _, entry in ipairs(entries) do
        table.insert(lines, entry.version .. " " .. entry.path .. " (" .. (entry.note or "") .. ")")
    end
    return table.concat(lines, "\n")
end

local function check(label, expected, actual)
    if expected ~= actual then
        error(label .. "\nexpected:\n" .. expected .. "\ngot:\n" .. actual, 2)
    end
end

-- Scoop lists the version directories, then current, a link to one of them.
install("C:\\Users\\John Doe\\scoop\\apps\\elixir\\1.16.2", "1.16.2")
install("C:\\Users\\John Doe\\scoop\\apps\\elixir\\current", "1.16.2")
dirs["C:\\Users\\John Doe\\scoop\\apps\\elixir"] = { "1.16.2", "current" }

-- The official installer's default directory.
install("C:\\Program Files\\Elixir", "1.15.7")

-- mise names its Windows installs after the release and the OTP release.
install("C:\\Users\\John Doe\\AppData\\Local\\mise\\installs\\elixir\\1.16.2-elixir-otp-26", "1.16.2")
dirs["C:\\Users\\John Doe\\AppData\\Local\\mise\\installs\\elixir"] = { "1.16.2-elixir-otp-26" }

-- where lists the vfox install first, which must not be reported; the installer
-- directory it lists next is already found.
install("C:\\Users\\John Doe\\.version-fox\\cache\\elixir\\v-1.99.0", "1.99.0")
commands["where elixir 2>nul"] = {
    "C:\\Users\\John Doe\\.version-fox\\cache\\elixir\\v-1.99.0\\bin\\elixir.bat",
    "C:\\Program Files\\Elixir\\bin\\elixir.bat",
}

local result = detect_elixir.find_all()
check(
    "Windows installs",
    table.concat({
        "1.15.7 C:\\Program Files\\Elixir (system Elixir)",
        "1.16.2 C:\\Users\\John Doe\\scoop\\apps\\elixir\\1.16.2 (installed by Scoop)",
        "1.16.2-elixir-otp-26 C:\\Users\\John Doe\\AppData\\Local\\mise\\installs\\elixir\\1.16.2-elixir-otp-26 (installed by mise)",
    }, "\n"),
    found(result)
)

local hook = plugin:Detect({})
check("Detect hook", found(result), found(hook))
