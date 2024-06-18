local elixirUtils = require("elixir_utils")

--- Return all available versions provided by this plugin
--- @param ctx table Empty table used as context, for future extension
--- @return table Descriptions of available versions and accompanying tool descriptions
function PLUGIN:Available(ctx)
    if RUNTIME.osType == "windows" then
        return  elixirUtils.get_elixir_release_verions_in_windows()
    end
    return  elixirUtils.get_elixir_release_verions_in_linux()
end