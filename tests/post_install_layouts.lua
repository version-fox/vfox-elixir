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

-- This file is not named *_test.lua on purpose. It runs the shell command of
-- PostInstall for real, in a directory whose path has a space, with a fake make
-- and erlc that it writes itself, and `vfox plugin test` disables os.execute.
-- It runs under glua instead, in the Test Plugin workflow on Ubuntu and macOS:
--   go run github.com/yuin/gopher-lua/cmd/glua@v1.1.1 tests/post_install_layouts.lua
PLUGIN = {}
RUNTIME = { osType = "linux", archType = "amd64", version = "" }
package.path = "./lib/?.lua;" .. package.path

-- lib/elixir_utils.lua loads the http module for the version lists, which
-- a build never uses.
package.preload["http"] = function()
    return {
        get = function()
            error("the layout test makes no requests")
        end,
        download_file = function()
            error("the layout test makes no requests")
        end,
    }
end
dofile("hooks/post_install.lua")

local function quote(value)
    return "'" .. value:gsub("'", "'\\''") .. "'"
end
local function command(value)
    assert(os.execute(value) == 0, value)
end
local function write(path, content)
    local file = assert(io.open(path, "w"))
    assert(file:write(content))
    assert(file:close())
end
local function read(path)
    local file = io.open(path, "r")
    if not file then
        return nil
    end
    local content = file:read("*a")
    file:close()
    return content
end

-- The fake make records the directory it ran in and the PATH it saw. It fails
-- when the directory holds a file named fail.
local MAKE = [[#!/bin/sh
if [ -e fail ]; then
    echo "make: failing on purpose" >&2
    exit 2
fi
{ pwd; printf '%s\n' "$PATH"; } > make.log
]]

-- erlc is looked for on PATH first, and a real one would win over the fake
-- one this test puts in the cache, so that case is skipped when erlc exists.
local erlc_on_path = os.execute("command -v erlc >/dev/null 2>&1") == 0

local root = os.tmpname() .. "-elixir-layout"
command("mkdir -p " .. quote(root))

-- The first word of the install path below names this directory. An unquoted
-- cd stops there, so make would run here and the install would report success
-- without building anything (issue #20).
local decoy = root .. "/vfox"
command("mkdir -p " .. quote(decoy))

-- VFOX_HOME may hold a space, so the install directory does too. The Erlang/OTP
-- layout is the one vfox-erlang's source build leaves: release/bin holds the
-- erlc that runs make.
local home = root .. "/vfox home"
local sdk = home .. "/cache/elixir/v-1.16.2/elixir-1.16.2"
local otp_root = home .. "/cache/erlang/v-26.2.3/erlang-26.2.3"
local erlang_bin = otp_root .. "/release/bin"
-- OTP's bootstrap compiler has an erlc too, and it has no make module. Its
-- erlc fails when run, so choosing it would fail the build below.
local bootstrap_bin = otp_root .. "/bootstrap/bin"
command("mkdir -p " .. quote(sdk) .. " " .. quote(erlang_bin) .. " " .. quote(bootstrap_bin))
write(erlang_bin .. "/erlc", "#!/bin/sh\nexit 0\n")
write(erlang_bin .. "/make", MAKE)
write(bootstrap_bin .. "/erlc", "#!/bin/sh\necho 'bootstrap erlc was chosen' >&2\nexit 1\n")
command(
    "chmod +x "
        .. quote(erlang_bin .. "/erlc")
        .. " "
        .. quote(erlang_bin .. "/make")
        .. " "
        .. quote(bootstrap_bin .. "/erlc")
)

local ctx = { sdkInfo = { elixir = { path = sdk, version = "1.16.2" } } }

if erlc_on_path then
    print("erlc is on PATH: skipping the case that finds Erlang/OTP in the cache")
else
    -- make runs in the source directory, and the Erlang/OTP bin directory is
    -- first on its PATH.
    PLUGIN:PostInstall(ctx)
    assert(read(decoy .. "/make.log") == nil, "make ran in " .. decoy .. ", the first word of the install path")
    local log = assert(read(sdk .. "/make.log"), "make did not run in the install directory")
    local dir, path_line = log:match("^(.-)\n(.-)\n$")
    assert(dir == sdk, "make ran in " .. tostring(dir) .. ", not " .. sdk)
    assert(
        path_line and path_line:sub(1, #erlang_bin + 1) == erlang_bin .. ":",
        "PATH should start with the Erlang/OTP release bin directory, got " .. tostring(path_line)
    )
end

-- A failing make stops the install with its message. Written last: pcall
-- catches the error, and gopher-lua closures stop seeing later assignments to
-- the locals around them.
if not erlc_on_path then
    write(sdk .. "/fail", "")
    local ok, err = pcall(function()
        PLUGIN:PostInstall(ctx)
    end)
    assert(not ok and tostring(err):find("Elixir build failed", 1, true), "failing make: " .. tostring(err))
end

command("rm -rf " .. quote(root))
print("post install layouts: ok")
