local http = require("http")

local elixir_utils = {}

function elixir_utils.peek_lua_table(o, indent)
    indent = indent or 0

    local function handle_table(t, currentIndent)
        local result = {}
        for k, v in pairs(t) do
            local key = type(k) ~= 'number' and ('[' .. peek_lua_table(k, currentIndent + 1) .. ']') or ''
            local value = type(v) == 'table' and handle_table(v, currentIndent + 1) or peek_lua_table(v, currentIndent + 1)
            table.insert(result, key .. (key ~= '' and ' = ' or '') .. value)
        end
        return '{\n' .. table.concat(result, ',\n') .. '\n' .. string.rep('  ', currentIndent) .. '}'
    end

    if type(o) == 'table' then
        return handle_table(o, indent)
    else
        return tostring(o)
    end
end

function elixir_utils.check_platform()
    if RUNTIME.OS_TYPE == "windows" then
        error("Windows is not supported. Please direct use the offcial installer to setup Elixir. visit: https://elixir-lang.org/install.html#windows")
    end
end

function elixir_utils.windows_install_exe(version)
    local installer = RUNTIME.pluginDirPath .. "\\" .. version .. ".exe"
    local elixir_version = string.gsub(version, "-", "/", 1)
    local download_url = "https://github.com/elixir-lang/elixir/releases/download/v" .. elixir_version .. ".exe"

    -- download
    print("Downloading installer...")
    print("from:\t" .. download_url)
    print("to:\t" .. installer)
    local err = http.download_file({
        url = download_url
    }, installer)

    if err ~= nil then
        error("Downloading installer failed")
    end

    -- Install exe
    -- FIXME: ..\\.. path
    local install_cmd = installer .. " -Wait -PassThru" .. " /S /D=" .. RUNTIME.pluginDirPath .. "\\..\\..\\cache\\elixir\\v-" .. version .. "\\elixir-" .. version
    print("install cmd: " .. install_cmd)
    local status = os.execute(install_cmd)
    if status ~= 0 then
        error("Erlang/OTP install failed, please check the stdout for details.")
    end
end

function elixir_utils.check_version_existence(url)
    local resp, err = http.get({
        url = url
    })
    if err ~= nil or resp.status_code ~= 200 then
        error("Please confirm whether the corresponding Elixir release version exists! visit: https://github.com/elixir-lang/elixir/releases")
    end
end

function elixir_utils.check_erlang_existence()
    print("Check Erlang/OTP existence...")
    local status = os.execute("which erlc")
    if status ~= 0 then
        error("Please install Erlang/OTP before you install Elixir.")
    end
end

function elixir_utils.get_elixir_release_verions_in_linux()
    local resp, err = http.get({
        url = "https://fastly.jsdelivr.net/gh/version-fox/vfox-elixir@main/assets/versions.txt"
    })
    local result = {}
    for version in string.gmatch(resp.body, '([^\n]+)') do
        table.insert(result, {
            version = version
        })
    end
    return result
end

function elixir_utils.get_elixir_release_verions_in_windows()
    local resp, err = http.get({
        url = "https://fastly.jsdelivr.net/gh/version-fox/vfox-elixir@main/assets/versions_win.txt"
    })
    local result = {}
    for version in string.gmatch(resp.body, '([^\n]+)') do
        table.insert(result, {
            version = version
        })
    end
    return result
end

return elixir_utils