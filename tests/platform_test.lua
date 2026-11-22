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
local platform = require("platform")

local function check(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

check(platform.join("/a", "b"), "/a/b", "join")
check(platform.join("/a/", "b"), "/a/b", "join keeps one separator")
check(platform.join("", "b"), "", "an empty base stays empty")
check(platform.child("/a", "lib/elixir", "ebin"), "/a/lib/elixir/ebin", "child splits segments")
check(platform.dirname("/usr/bin/elixir"), "/usr/bin", "dirname")
check(platform.dirname("/usr"), nil, "dirname of a top-level name")
check(platform.basename("/a/b/1.16.2-otp-26"), "1.16.2-otp-26", "basename")
check(platform.shell_quote("it's"), "'it'\\''s'", "shell quote")
check(platform.trim("  x \r\n"), "x", "trim")
check(platform.env("VFOX_ELIXIR_NOT_SET_FOR_TESTS"), nil, "unset variable")

-- io.popen as vfox 1.1.0 gives it on Windows: a handle with read, write and close,
-- and no lines method. read("*l") returns the next line without its line ending,
-- and nil after the last one. The commands are not run; the output is given.
local function windows_popen(output)
    return function()
        local position = 1
        return {
            read = function(_, format)
                assert(format == nil or format == "*l", "unexpected read format " .. tostring(format))
                if position > #output then
                    return nil
                end
                local stop = output:find("\n", position, true)
                local line
                if stop then
                    line = output:sub(position, stop - 1)
                    position = stop + 1
                else
                    line = output:sub(position)
                    position = #output + 1
                end
                return (line:gsub("\r$", ""))
            end,
            close = function()
                return true
            end,
        }
    end
end

local saved_popen = io.popen
local saved_os_type = RUNTIME.osType
RUNTIME.osType = "windows"

io.popen = windows_popen("Erlang OTP 26\r\n\r\n  Git  \r\nlast line without a newline")
local lines = platform.lines('dir /b /ad "C:\\Program Files" 2>nul')
assert(
    #lines == 3 and lines[1] == "Erlang OTP 26" and lines[2] == "Git" and lines[3] == "last line without a newline",
    "windows lines: " .. table.concat(lines, "|")
)

io.popen = windows_popen("Erlang OTP 26\r\nGit\r\n")
local children = platform.list_children("C:\\Program Files")
assert(
    #children == 2 and children[1] == "C:\\Program Files\\Erlang OTP 26" and children[2] == "C:\\Program Files\\Git",
    "windows children: " .. table.concat(children, "|")
)

io.popen = saved_popen
RUNTIME.osType = saved_os_type
