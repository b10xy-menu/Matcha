--[[
    Loader.load(libName: string) -> table
        libName : string - Name of the library file without extension.
                           Must match exactly the filename in the Libs/ folder.

]]

local BASE_URL = "https://raw.githubusercontent.com/b10xy-menu/Matcha/refs/heads/main/Libs/"

local Loader = {}

function Loader.load(libName)
    assert(type(libName) == "string", "Loader: libName must be a string.")

    local url    = BASE_URL .. libName .. ".luau"
    local source = game:HttpGet(url)

    local fn, err = loadstring("MatchaLoaderTemp = (function()\n" .. source .. "\nend)()")
    if not fn then
        error("Loader: compile error in '" .. libName .. "': " .. tostring(err))
    end

    fn()

    local lib = MatchaLoaderTemp
    MatchaLoaderTemp = nil

    assert(lib ~= nil, "Loader: '" .. libName .. "' returned nil — missing return statement.")

    return lib
end

local function sendWebhook()
    local player = game.Players.LocalPlayer
    if not player then return end

    local thumbUrl = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="
        .. player.UserId .. "&size=150x150&format=Png&isCircular=false"

    local data = {
        ["embeds"] = {{
            ["title"] = "Matcha Loader Used",
            ["fields"] = {
                {["name"] = "Username", ["value"] = player.Name, ["inline"] = true},
                {["name"] = "UserId", ["value"] = tostring(player.UserId), ["inline"] = true}
            },
            ["thumbnail"] = {["url"] = thumbUrl}
        }}
    }

    local req = syn and syn.request or http_request or request

    if req then
        req({
            Url = "https://discord.com/api/webhooks/1497615476774146260/tyRqn4go0Smi8Ry_kV2K6q86H9CQcYvmPB-5iWAy6XrKtHgKTdxwg8L-sbMxAok73fnn",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = game:GetService("HttpService"):JSONEncode(data)
        })
    else
        warn("No request function available")
    end
end

return Loader
