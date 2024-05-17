
--- When user invoke `use` command, this function will be called to get the
--- valid version information.
--- @param ctx table Context information
function PLUGIN:PreUse(ctx)
    --- user input version
    local input_version = ctx.version

    --- installed sdks
    local sdkInfo = ctx.installedSdks[input_version]
    local used_version = sdkInfo.version

    --- return the version information
    return {
        version = used_version
    }
end