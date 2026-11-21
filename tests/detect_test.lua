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
    os = "linux",
    arch = "amd64",
    env = { HOME = "/home/u" },
})
local detect_elixir = require("detect_elixir")

-- A fake filesystem. files maps a path to its content, dirs maps a directory to
-- the names of its children, and commands maps a shell command to its output.
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
        local dir = command:match("^ls %-1 '(.*)' 2>/dev/null$")
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

-- An Elixir install: its launcher, and a VERSION file or an elixir.app.
local function install(root, version)
    files[root .. "/bin/elixir"] = ""
    if version then
        files[root .. "/VERSION"] = version .. "\n"
    end
end

local function app(root, vsn)
    files[root .. "/bin/elixir"] = ""
    files[root .. "/lib/elixir/ebin/elixir.app"] = '{application,elixir,\n [{description,"elixir"},\n  {vsn,"'
        .. vsn
        .. '"},\n'
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

-- asdf and mise name the directory after the release, so the directory name
-- is the version, even without a VERSION file.
install("/home/u/.asdf/installs/elixir/1.16.2-otp-26", "1.16.2")
commands["command -v elixir 2>/dev/null"] = {}
dirs["/home/u/.asdf/installs/elixir"] = { "1.16.2-otp-26" }
app("/home/u/.local/share/mise/installs/elixir/1.17.0-otp-27", "1.17.0")
dirs["/home/u/.local/share/mise/installs/elixir"] = { "1.17.0-otp-27" }

-- Homebrew keeps the files of a keg under libexec, which the keg's bin/ links into.
app("/opt/homebrew/opt/elixir/libexec", "1.18.4")
dirs["/opt/homebrew/opt"] = { "elixir" }
-- A keg of another prefix keeps its files at the top, with a VERSION file.
install("/usr/local/opt/elixir", "1.18.3")
dirs["/usr/local/opt"] = { "elixir" }

-- Debian and Ubuntu ship no VERSION file, only the elixir.app of the library.
app("/usr/lib/elixir", "1.14.0")
commands["command -v elixir 2>/dev/null"] = { "/usr/bin/elixir" }
commands["readlink -f '/usr/bin/elixir' 2>/dev/null"] = { "/usr/lib/elixir/bin/elixir" }

-- A directory whose name is not a version is skipped, and so is one without a launcher.
-- A name vfox would refuse to link (it must start with a letter or digit) is skipped too.
install("/home/u/.asdf/installs/elixir/bad name", "1.0.0")
install("/home/u/.asdf/installs/elixir/-1.0.0-otp-25", "1.0.0")
files["/home/u/.asdf/installs/elixir/1.15.0-otp-25/VERSION"] = "1.15.0\n"
dirs["/home/u/.asdf/installs/elixir"] = { "1.16.2-otp-26", "bad name", "-1.0.0-otp-25", "1.15.0-otp-25" }

local result = detect_elixir.find_all()
check(
    "Unix installs",
    table.concat({
        "1.14.0 /usr/lib/elixir (system Elixir)",
        "1.16.2-otp-26 /home/u/.asdf/installs/elixir/1.16.2-otp-26 (installed by asdf)",
        "1.17.0-otp-27 /home/u/.local/share/mise/installs/elixir/1.17.0-otp-27 (installed by mise)",
        "1.18.3 /usr/local/opt/elixir (installed by Homebrew)",
        "1.18.4 /opt/homebrew/opt/elixir/libexec (installed by Homebrew)",
    }, "\n"),
    found(result)
)

-- A vfox install is never reported, even when PATH resolves to it.
files = {}
dirs = {}
commands = {}
install("/home/u/.version-fox/cache/elixir/v-1.99.0", "1.99.0")
commands["command -v elixir 2>/dev/null"] = { "/home/u/.version-fox/cache/elixir/v-1.99.0/bin/elixir" }
commands["readlink -f '/home/u/.version-fox/cache/elixir/v-1.99.0/bin/elixir' 2>/dev/null"] =
    { "/home/u/.version-fox/cache/elixir/v-1.99.0/bin/elixir" }
check("vfox install is skipped", "", found(detect_elixir.find_all()))

-- An install found on PATH is reported with its note, once.
files = {}
dirs = {}
commands = {}
install("/home/u/bin/elixir-src", "1.19.0")
commands["command -v elixir 2>/dev/null"] = { "/home/u/bin/elixir-src/bin/elixir" }
commands["readlink -f '/home/u/bin/elixir-src/bin/elixir' 2>/dev/null"] = { "/home/u/bin/elixir-src/bin/elixir" }
check("PATH install", "1.19.0 /home/u/bin/elixir-src (found on PATH)", found(detect_elixir.find_all()))

-- The plugin itself exposes Detect, which returns the same list.
local hook = plugin:Detect({})
check("Detect hook", "1.19.0 /home/u/bin/elixir-src (found on PATH)", found(hook))
