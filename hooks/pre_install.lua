local elixirUtils = require("elixir_utils")

--- Returns some pre-installed information, such as version number, download address, local files, etc.
--- If checksum is provided, vfox will automatically check it for you.
--- @param ctx table
--- @field ctx.version string User-input version
--- @return table Version information
function PLUGIN:PreInstall(ctx)
    
    elixirUtils.check_platform()

    local elixir_version = ctx.version
    if elixir_version == nil then
        print("You will install the elixir version is" .. elixir_version)
        error("You must provide a version number for Elixir, eg: vfox install elixir@1.16.2")
    end
    elixirUtils.check_version_existence("https://github.com/elixir-lang/elixir/releases/tag/v" .. elixir_version)
    
    local download_url = "https://github.com/elixir-lang/elixir/archive/refs/tags/v" .. elixir_version .. ".tar.gz"
    return {
        version = elixir_version,
        url = download_url
    }
end