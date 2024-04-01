--- Extension point, called after PreInstall, can perform additional operations,
--- such as file operations for the SDK installation directory or compile source code
--- Currently can be left unimplemented!
function PLUGIN:PostInstall(ctx)
    --- ctx.rootPath SDK installation directory
    local sdkInfo = ctx.sdkInfo['elixir']
    local path = sdkInfo.path
    local status = os.execute("cd " .. path .. " && make")
    if status ~= 0 then
        error("Elixir install failed, please check the stdout for details.")
    end
end