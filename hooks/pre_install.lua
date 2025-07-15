local elixirUtils = require("elixir_utils")

--- Returns some pre-installed information, such as version number, download address, local files, etc.
--- If checksum is provided, vfox will automatically check it for you.
--- @param ctx table
--- @field ctx.version string User-input version
--- @return table Version information
function PLUGIN:PreInstall(ctx)
    local elixir_version = ctx.version
    if elixir_version == nil then
        error("You must provide a version number for Elixir, eg: vfox install elixir@1.16.2")
    end

    local download_url
    print("You will install the elixir version is " .. elixir_version)

    if os.getenv("VFOX_ELIXIR_MIRROR") == "hex" then
        download_url = elixirUtils.get_hex_prebuild_url(elixir_version)
    else
        if RUNTIME.osType == "windows" then
            return {
                version = elixir_version,
            }
        else
            elixirUtils.check_version_existence("https://github.com/elixir-lang/elixir/releases/tag/v" .. elixir_version)
            download_url = "https://github.com/elixir-lang/elixir/archive/refs/tags/v" .. elixir_version .. ".tar.gz"
        end
    end


    return {
        version = elixir_version,
        url = download_url,
    }
end