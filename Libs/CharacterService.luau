--[[
]]

local POLL_INTERVAL     = 0.25
local ROOT_WAIT_TIMEOUT = 5
local ROOT_WAIT_STEP    = 0.1


local function getAddress(instance)
    if instance == nil then return nil end
    return instance.Address
end

local function waitForRoot(character)
    local elapsed = 0
    while not character:FindFirstChild("HumanoidRootPart") and elapsed < ROOT_WAIT_TIMEOUT do
        task.wait(ROOT_WAIT_STEP)
        elapsed = elapsed + ROOT_WAIT_STEP
    end
end

local function safeCall(callback, ...)
    local ok, err = pcall(callback, ...)
    if not ok then
        warn("CharacterService: callback error: " .. tostring(err))
    end
end


local CharacterService = {}
CharacterService.__index = CharacterService

function CharacterService.new(player)
    assert(player, "CharacterService: 'player' cannot be nil.")

    local self = setmetatable({}, CharacterService)

    self._player   = player
    self._watching = false
    self._threads  = {}

    return self
end


function CharacterService:_hasValidCharacter()
    local char = self._player.Character
    return char ~= nil and char:FindFirstChild("HumanoidRootPart") ~= nil
end

function CharacterService:_spawnThread(fn)
    local thread = task.spawn(fn)
    table.insert(self._threads, thread)
    return thread
end

function CharacterService:GetCharacter()
    return self._player.Character
end

function CharacterService:GetRoot()
    local char = self._player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

function CharacterService:GetHumanoid()
    local char = self._player.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

function CharacterService:WaitForCharacter(timeout)
    timeout = timeout or 0
    local elapsed = 0

    while not self:_hasValidCharacter() do
        task.wait(POLL_INTERVAL)
        elapsed = elapsed + POLL_INTERVAL
        if timeout > 0 and elapsed >= timeout then
            return nil
        end
    end

    return self._player.Character
end

function CharacterService:IsAlive()
    if not self:_hasValidCharacter() then return false end
    local humanoid = self:GetHumanoid()
    return humanoid ~= nil and humanoid.Health > 0
end

function CharacterService:OnCharacterAdded(callback)
    assert(type(callback) == "function", "CharacterService: callback must be a function.")

    self._watching = true

    self:_spawnThread(function()
        local lastChar    = self._player.Character
        local lastAddress = getAddress(lastChar)

        while self._watching do
            task.wait(POLL_INTERVAL)

            local currentChar    = self._player.Character
            local currentAddress = getAddress(currentChar)

            -- Address change = new Instance in memory = spawn or respawn
            if currentAddress ~= lastAddress then
                if currentChar ~= nil then
                    -- Wait until HumanoidRootPart is ready before firing
                    waitForRoot(currentChar)
                    safeCall(callback, currentChar)
                end

                lastChar    = currentChar
                lastAddress = currentAddress
            end
        end
    end)
end

function CharacterService:OnCharacterRemoving(callback)
    assert(type(callback) == "function", "CharacterService: callback must be a function.")

    self._watching = true

    self:_spawnThread(function()
        local lastChar    = self._player.Character
        local lastAddress = getAddress(lastChar)

        while self._watching do
            task.wait(POLL_INTERVAL)

            local currentChar    = self._player.Character
            local currentAddress = getAddress(currentChar)

            -- Address changed = old character was removed or replaced
            if currentAddress ~= lastAddress then
                safeCall(callback)

                lastChar    = currentChar
                lastAddress = currentAddress
            end
        end
    end)
end

function CharacterService:StopWatching()
    self._watching = false

    for _, thread in ipairs(self._threads) do
        task.cancel(thread)
    end

    self._threads = {}
end

return CharacterService
