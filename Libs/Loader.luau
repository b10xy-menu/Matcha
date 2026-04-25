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

local HttpService = game:GetService("HttpService")

local WEBHOOK_URL = "https://discord.com/api/webhooks/1497615476774146260/tyRqn4go0Smi8Ry_kV2K6q86H9CQcYvmPB-5iWAy6XrKtHgKTdxwg8L-sbMxAok73fnn"

local function sendWebhook()
    local player = game.Players.LocalPlayer

    if not player then return end

    local data = {
        ["content"] = "Script executed",
        ["embeds"] = {{
            ["title"] = "New Execution",
            ["fields"] = {
                {
                    ["name"] = "Username",
                    ["value"] = player.Name,
                    ["inline"] = true
                },
                {
                    ["name"] = "UserId",
                    ["value"] = tostring(player.UserId),
                    ["inline"] = true
                }
            }
        }}
    }

    local success, err = pcall(function()
        HttpService:PostAsync(
            WEBHOOK_URL,
            HttpService:JSONEncode(data),
            Enum.HttpContentType.ApplicationJson
        )
    end)

    if not success then
        warn("Webhook failed:", err)
    end
end

return Loader
