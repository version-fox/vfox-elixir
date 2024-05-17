local elixirUtils = require("elixir_utils")

--- Extension point, called after PreInstall, can perform additional operations,
--- such as file operations for the SDK installation directory or compile source code
--- Currently can be left unimplemented!
function PLUGIN:PostInstall(ctx)
    --- ctx.rootPath SDK installation directory
    local sdkInfo = ctx.sdkInfo['elixir']
    local path = sdkInfo.path
    local install_cmd

    if RUNTIME.osType == "windows" then
        return elixirUtils.windows_install_exe(sdkInfo.version)
    else
        install_cmd = "cd " .. path .. " && make"
    end

    local status = os.execute(install_cmd)
    if status ~= 0 then
        error("Elixir install failed, please check the stdout for details.")
    end
end