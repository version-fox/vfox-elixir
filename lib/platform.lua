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

--- Small helpers for paths, shell commands and files that depend on the
--- platform vfox runs on. Shared by lib/elixir_utils.lua and lib/detect_elixir.lua.
local platform = {}

--- Returns true when vfox runs the plugin on Windows.
function platform.is_windows()
    return RUNTIME ~= nil and RUNTIME.osType == "windows"
end

--- Returns the path separator of the platform: `\` on Windows, `/` elsewhere.
function platform.separator()
    if platform.is_windows() then
        return "\\"
    end
    return "/"
end

--- Joins two path segments with the platform separator. An empty left side
--- stays empty, so a missing environment variable never yields a rooted path.
function platform.join(left, right)
    if left == nil or left == "" then
        return ""
    end
    local last = left:sub(-1)
    if last == "/" or last == "\\" then
        return left .. right
    end
    return left .. platform.separator() .. right
end

--- Joins a base directory and the segments below it with the platform
--- separator. A segment may hold several names separated by "/" or "\", such
--- as "lib/elixir", so the result never mixes separators.
function platform.child(base, ...)
    local path = base
    for _, segment in ipairs({ ... }) do
        for part in segment:gmatch("[^/\\]+") do
            path = platform.join(path, part)
        end
    end
    return path
end

--- Returns the parent directory of a path, or nil when it has none.
function platform.dirname(path)
    local parent = path:match("^(.*)[/\\][^/\\]+$")
    if parent == nil or parent == "" then
        return nil
    end
    return parent
end

--- Returns the last segment of a path.
function platform.basename(path)
    return path:match("([^/\\]+)$") or path
end

--- Returns text without leading and trailing whitespace.
function platform.trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

--- Returns the value of an environment variable, or nil when it is unset or empty.
function platform.env(name)
    local value = os.getenv(name)
    if value == nil or value == "" then
        return nil
    end
    return value
end

--- Quotes a value for the shell that os.execute uses: cmd.exe on Windows, sh elsewhere.
function platform.shell_quote(value)
    if platform.is_windows() then
        return '"' .. value:gsub('"', '""') .. '"'
    end
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

--- Returns every line of a shell command's output, without surrounding
--- whitespace and without blank lines. Returns {} when the command cannot run.
function platform.lines(command)
    if io.popen == nil then
        return {}
    end
    local handle = io.popen(command, "r")
    if not handle then
        return {}
    end
    local result = {}
    for line in handle:lines() do
        line = platform.trim(line)
        if line ~= "" then
            table.insert(result, line)
        end
    end
    handle:close()
    return result
end

--- Returns the first line of a shell command's output, or nil.
function platform.first_line(command)
    return platform.lines(command)[1]
end

--- Lists the immediate children of a directory as full paths, or {}.
--- Files appear too on Unix; callers check what they expect.
function platform.list_children(dir)
    if dir == nil or dir == "" then
        return {}
    end
    local command
    if platform.is_windows() then
        command = "dir /b /ad " .. platform.shell_quote(dir) .. " 2>nul"
    else
        command = "ls -1 " .. platform.shell_quote(dir) .. " 2>/dev/null"
    end
    local result = {}
    for _, name in ipairs(platform.lines(command)) do
        if name ~= "." and name ~= ".." then
            table.insert(result, platform.join(dir, name))
        end
    end
    return result
end

--- Returns true when the path can be opened for reading. A directory counts
--- as well on Unix, so callers that need a file read it as well.
function platform.file_exists(path)
    local file = io.open(path, "r")
    if file == nil then
        return false
    end
    file:close()
    return true
end

--- Returns the content of a file, or nil when it cannot be read.
function platform.read_file(path)
    local file = io.open(path, "r")
    if file == nil then
        return nil
    end
    local content = file:read("*a")
    file:close()
    return content
end

return platform
