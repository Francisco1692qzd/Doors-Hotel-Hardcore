-- [[ HARDCORE WITH PROPER MULTIPLAYER SYNC (FIXED) ]]
repeat task.wait() until game:IsLoaded()

local Player = game.Players.LocalPlayer
local LatestRoom = game.ReplicatedStorage.GameData.LatestRoom
local TS = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local opened = false

-- ============================================
-- SIMPLE CONFIG
-- ============================================
local CONFIG = {
    RIPPER_DELAY = {75, 115},
    REBOUND_DELAY = {480, 730},
    FROSTBITE_DELAY = {355, 830},
    FROSTBITE_MIN_ROOM = 20,
    CEASE_DELAY = {50, 80},
    A60_DELAY = {1750, 2400},
    SILENCE_DELAY = {600, 900},
    DEERGOD_DELAY = {900, 1200},
    SHOCKER_DELAY = {25, 50},
}

-- ============================================
-- MULTIPLAYER SYNC SYSTEM
-- ============================================
local syncFolder = ReplicatedStorage:FindFirstChild("HardcoreSync") or Instance.new("Folder", ReplicatedStorage)
syncFolder.Name = "HardcoreSync"

local masterStart = syncFolder:FindFirstChild("MasterStart") or Instance.new("NumberValue", syncFolder)
masterStart.Name = "MasterStart"

local nextSpawn = syncFolder:FindFirstChild("NextSpawn") or Instance.new("StringValue", syncFolder)
nextSpawn.Name = "NextSpawn"

local spawnLock = syncFolder:FindFirstChild("SpawnLock") or Instance.new("BoolValue", syncFolder)
spawnLock.Name = "SpawnLock"
spawnLock.Value = false

local isMaster = false

local function TryBecomeMaster()
    if masterStart.Value == 0 then
        masterStart.Value = workspace:GetServerTimeNow()
        isMaster = true
        print("🎮 Master player: " .. Player.Name)
    end
end

local function ScheduleSpawn(entityName, absoluteTime)
    if not isMaster then return false end
    if spawnLock.Value then return false end
    spawnLock.Value = true
    nextSpawn.Value = entityName .. ":" .. tostring(absoluteTime)
    spawnLock.Value = false
    return true
end

-- ============================================
-- ENTITY SPAWNING FUNCTIONS
-- ============================================
local entityURLs = {
    Ripper = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/refs/heads/main/ripper.lua",
    Rebound = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/refs/heads/main/rebound.lua",
    DeerGod = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/refs/heads/main/deergod.lua",
    Cease = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/refs/heads/main/cease.lua",
    Shocker = "https://raw.githubusercontent.com/Francisco1692qzd/RevivedOldHardcore/refs/heads/main/oldShocker.lua",
    Silence = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/refs/heads/main/silence.lua",
    A60 = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/refs/heads/main/a60.lua",
    Frostbite = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/refs/heads/main/frostbite.lua"
}

local lastEntitySpawnTime = 0
local ENTITY_SPAWN_COOLDOWN = 3
local isPlayerAlive = true

local function CanSpawnEntity(entityName)
    if not isPlayerAlive then return false end
    if workspace:FindFirstChild("SeekMovingNewClone") or workspace:FindFirstChild("SeekMoving") then
        return false
    end
    local latestRoom = LatestRoom.Value
    if latestRoom == 100 then return false end
    if latestRoom == 50 and entityName ~= "A60" then return false end
    if latestRoom == 51 or (latestRoom > 52 and latestRoom < 59) then return false end
    if workspace:GetServerTimeNow() - lastEntitySpawnTime < ENTITY_SPAWN_COOLDOWN then
        return false
    end
    local activeEntity = workspace:FindFirstChild("Death") or
        workspace:FindFirstChild("RushCounterpart") or
        workspace:FindFirstChild("ReboundMoving") or
        workspace:FindFirstChild("Deer God") or
        workspace:FindFirstChild("Cease") or
        workspace:FindFirstChild("Shocker") or
        workspace:FindFirstChild("Silence") or
        workspace:FindFirstChild("A-60") or
        workspace:FindFirstChild("Frostbite") or
        workspace:FindFirstChild("Ripper")
    return activeEntity == nil
end

local function SpawnEntity(entityName)
    if not isPlayerAlive then return false end
    if not entityURLs[entityName] then return false end
    if not CanSpawnEntity(entityName) then return false end
    lastEntitySpawnTime = workspace:GetServerTimeNow()
    local success, err = pcall(function()
        loadstring(game:HttpGet(entityURLs[entityName]))()
        print("🎮 Spawning: " .. entityName)
    end)
    if not success then
        warn("Failed to spawn " .. entityName .. ": " .. tostring(err))
        return false
    end
    return true
end

-- ============================================
-- SYNC LISTENER
-- ============================================
nextSpawn.Changed:Connect(function()
    if nextSpawn.Value == "" then return end
    local parts = {}
    for part in string.gmatch(nextSpawn.Value, "[^:]+") do
        table.insert(parts, part)
    end
    if #parts >= 2 then
        local entityName = parts[1]
        local spawnTime = tonumber(parts[2])
        while workspace:GetServerTimeNow() < spawnTime do
            task.wait(0.05)
        end
        if CanSpawnEntity(entityName) then
            SpawnEntity(entityName)
            print("🎮 SYNC SPAWN: " .. entityName .. " at room " .. LatestRoom.Value)
        end
        task.wait(0.5)
        nextSpawn.Value = ""
    end
end)

-- ============================================
-- DETERMINISTIC DELAYS
-- ============================================
local spawnDelays = {
    Ripper = 0, Rebound = 0, Frostbite = 0,
    Cease = 0, Shocker = 0, A60 = 0, Silence = 0, DeerGod = 0
}

local JobId = game.JobId
local function getDeterministicSeed(jobId)
    local seed = 0
    for i = 1, #jobId do
        seed = (seed * 31 + string.byte(jobId, i)) % 2^32
    end
    return seed
end

local function initSharedRandom()
    math.randomseed(getDeterministicSeed(JobId))
end

local function CalculateSpawnDelays()
    spawnDelays.Ripper = math.random(CONFIG.RIPPER_DELAY[1], CONFIG.RIPPER_DELAY[2])
    spawnDelays.Rebound = math.random(CONFIG.REBOUND_DELAY[1], CONFIG.REBOUND_DELAY[2])
    spawnDelays.Frostbite = math.random(CONFIG.FROSTBITE_DELAY[1], CONFIG.FROSTBITE_DELAY[2])
    spawnDelays.Cease = math.random(CONFIG.CEASE_DELAY[1], CONFIG.CEASE_DELAY[2])
    spawnDelays.Shocker = math.random(CONFIG.SHOCKER_DELAY[1], CONFIG.SHOCKER_DELAY[2])
    spawnDelays.A60 = math.random(CONFIG.A60_DELAY[1], CONFIG.A60_DELAY[2])
    spawnDelays.Silence = math.random(CONFIG.SILENCE_DELAY[1], CONFIG.SILENCE_DELAY[2])
    spawnDelays.DeerGod = math.random(CONFIG.DEERGOD_DELAY[1], CONFIG.DEERGOD_DELAY[2])
    print("📊 Spawn delays calculated")
end

-- ============================================
-- MASTER SCHEDULER (FIXED FOR DOOR WAIT)
-- ============================================
local function SetupMasterScheduler()
    if not isMaster then return end

    -- Track last spawn absolute time for each entity
    local lastSpawnAbsolute = {
        Ripper = masterStart.Value,
        Rebound = masterStart.Value,
        Frostbite = masterStart.Value,
        Cease = masterStart.Value,
        A60 = masterStart.Value,
        Silence = masterStart.Value,
        DeerGod = masterStart.Value,
    }

    -- Pending entities that are waiting for a door to open
    local pendingDoorWait = {}  -- entityName -> true

    -- Spawn immediate entities (Cease, A60, Silence, DeerGod)
    local function spawnImmediate(entity, absTime)
        if absTime <= workspace:GetServerTimeNow() then
            if CanSpawnEntity(entity) then
                ScheduleSpawn(entity, workspace:GetServerTimeNow() + 0.5)
            end
        else
            ScheduleSpawn(entity, absTime)
        end
    end

    -- Handle room-wait entities: mark as pending, will spawn on next door
    local function markPendingDoor(entity)
        pendingDoorWait[entity] = true
        print("⏳ " .. entity .. " ready – waiting for door to open")
    end

    -- Check timers and trigger spawns
    task.spawn(function()
        while isPlayerAlive and LatestRoom.Value >= 1 and LatestRoom.Value < 100 do
            local now = workspace:GetServerTimeNow()

            -- Ripper (room wait)
            if now - lastSpawnAbsolute.Ripper >= spawnDelays.Ripper then
                markPendingDoor("Ripper")
                lastSpawnAbsolute.Ripper = now
            end

            -- Rebound (room wait)
            if now - lastSpawnAbsolute.Rebound >= spawnDelays.Rebound then
                markPendingDoor("Rebound")
                lastSpawnAbsolute.Rebound = now
            end

            -- Frostbite (room wait)
            if LatestRoom.Value >= CONFIG.FROSTBITE_MIN_ROOM and now - lastSpawnAbsolute.Frostbite >= spawnDelays.Frostbite then
                markPendingDoor("Frostbite")
                lastSpawnAbsolute.Frostbite = now
            end

            -- Cease (immediate)
            if now - lastSpawnAbsolute.Cease >= spawnDelays.Cease then
                spawnImmediate("Cease", now + 0.5)
                lastSpawnAbsolute.Cease = now
            end

            -- A60 (immediate)
            if now - lastSpawnAbsolute.A60 >= spawnDelays.A60 then
                spawnImmediate("A60", now + 0.5)
                lastSpawnAbsolute.A60 = now
            end

            -- Silence (immediate)
            if now - lastSpawnAbsolute.Silence >= spawnDelays.Silence then
                spawnImmediate("Silence", now + 0.5)
                lastSpawnAbsolute.Silence = now
            end

            -- DeerGod (immediate)
            if now - lastSpawnAbsolute.DeerGod >= spawnDelays.DeerGod then
                spawnImmediate("DeerGod", now + 0.5)
                lastSpawnAbsolute.DeerGod = now
            end

            task.wait(0.5)
        end
    end)

    -- Listen for door changes (room number increases)
    local lastRoom = LatestRoom.Value
    LatestRoom.Changed:Connect(function()
        local newRoom = LatestRoom.Value
        if newRoom > lastRoom then  -- Door opened
            for entity, _ in pairs(pendingDoorWait) do
                if CanSpawnEntity(entity) then
                    ScheduleSpawn(entity, workspace:GetServerTimeNow() + 0.5)
                    print("🚪 DOOR SPAWN: " .. entity)
                else
                    -- If can't spawn now, keep pending for next door
                    print("⏳ " .. entity .. " still pending (blocked)")
                end
            end
            pendingDoorWait = {}  -- Clear after attempting to spawn all
        end
        lastRoom = newRoom
    end)
end

-- ============================================
-- LOCAL SPAWNER (Shocker only)
-- ============================================
local lastLocalSpawnTimes = { Shocker = 0 }
local function SetupLocalSpawners()
    task.spawn(function()
        while isPlayerAlive and LatestRoom.Value >= 1 and LatestRoom.Value < 100 do
            local now = workspace:GetServerTimeNow()
            if now - lastLocalSpawnTimes.Shocker >= spawnDelays.Shocker then
                if CanSpawnEntity("Shocker") then
                    SpawnEntity("Shocker")
                    lastLocalSpawnTimes.Shocker = now
                    print("⚡ Shocker (local)")
                end
            end
            task.wait(1)
        end
    end)
end

-- ============================================
-- STAMINA BAR (clean version)
-- ============================================
local UIS = game:GetService("UserInputService")
local stamina = 100
local maxStamina = 100
local isExhausted = false
local sprinting = false
local crouching = false

-- Create GUI
local staminaGui = Instance.new("ScreenGui")
staminaGui.Name = "StaminaGui"
staminaGui.ResetOnSpawn = false
staminaGui.IgnoreGuiInset = true
staminaGui.Parent = Player.PlayerGui

local staminaContainer = Instance.new("Frame")
staminaContainer.Size = UDim2.new(0, 280, 0, 12)
staminaContainer.Position = UDim2.new(0.5, 0, 0.92, -30)  -- centered bottom
staminaContainer.AnchorPoint = Vector2.new(0.5, 0.5)
staminaContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
staminaContainer.BackgroundTransparency = 0.4
staminaContainer.BorderSizePixel = 0
staminaContainer.ClipsDescendants = true
staminaContainer.Parent = staminaGui

local containerCorner = Instance.new("UICorner")
containerCorner.CornerRadius = UDim.new(0, 6)
containerCorner.Parent = staminaContainer

local staminaFill = Instance.new("Frame")
staminaFill.Size = UDim2.new(1, 0, 1, 0)
staminaFill.BackgroundColor3 = Color3.fromRGB(255, 222, 189)
staminaFill.BorderSizePixel = 0
staminaFill.Parent = staminaContainer

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 6)
fillCorner.Parent = staminaFill

local staminaText = Instance.new("TextLabel")
staminaText.Size = UDim2.new(1, 0, 1, 0)
staminaText.BackgroundTransparency = 1
staminaText.Text = "100%"
staminaText.TextColor3 = Color3.fromRGB(255, 255, 255)
staminaText.TextSize = 11
staminaText.Font = Enum.Font.GothamBold
staminaText.Parent = staminaContainer

-- Sprint input
UIS.InputBegan:Connect(function(i, gpe)
    if not gpe and i.KeyCode == Enum.KeyCode.Q then sprinting = true end
end)
UIS.InputEnded:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.Q then sprinting = false end
end)

-- Mobile sprint button
local function CreateSprintButton()
    if not UIS.TouchEnabled then return end
    local btnGui = Instance.new("ScreenGui")
    btnGui.Name = "SprintButtonGui"
    btnGui.ResetOnSpawn = false
    btnGui.IgnoreGuiInset = true
    btnGui.DisplayOrder = 999
    btnGui.Parent = Player.PlayerGui

    local button = Instance.new("ImageButton")
    button.Size = UDim2.new(0, 75, 0, 75)
    button.Position = UDim2.new(1, -90, 0.5, -30)
    button.AnchorPoint = Vector2.new(0.5, 0.5)
    button.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    button.BackgroundTransparency = 0.3
    button.BorderSizePixel = 0
    button.Image = "rbxassetid://6031094773"
    button.ScaleType = Enum.ScaleType.Fit
    button.Parent = btnGui

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(1, 0)
    btnCorner.Parent = button

    button.MouseButton1Down:Connect(function()
        if isPlayerAlive and stamina > 5 then
            sprinting = true
            button.ImageColor3 = Color3.fromRGB(255, 222, 189)
        end
    end)
    button.MouseButton1Up:Connect(function()
        sprinting = false
        button.ImageColor3 = Color3.fromRGB(255, 255, 255)
    end)
    button.MouseLeave:Connect(function()
        sprinting = false
        button.ImageColor3 = Color3.fromRGB(255, 255, 255)
    end)
end

-- Breath sound
local breathSound
local function SetupCharacter(char)
    local head = char:FindFirstChild("Head")
    if head then
        if breathSound then breathSound:Destroy() end
        breathSound = Instance.new("Sound", head)
        breathSound.SoundId = "rbxassetid://8258601891"
        breathSound.Volume = 2
        breathSound.Looped = true
    end
end

Player.CharacterAdded:Connect(function(char)
    isPlayerAlive = true
    stamina = 100
    isExhausted = false
    sprinting = false
    SetupCharacter(char)
end)

Player.CharacterRemoving:Connect(function()
    isPlayerAlive = false
    sprinting = false
end)

if Player.Character then SetupCharacter(Player.Character) end

-- Stamina update loop
task.spawn(function()
    while task.wait(0.05) do
        local char = Player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if not hum then continue end

        local isMoving = hum.MoveDirection.Magnitude > 0
        local seekActive = workspace:FindFirstChild("SeekMovingNewClone") or workspace:FindFirstChild("SeekMoving")
        crouching = char:GetAttribute("Crouching")

        local percent = stamina / maxStamina
        staminaFill.Size = UDim2.new(percent, 0, 1, 0)
        staminaText.Text = math.floor(stamina) .. "%"

        if stamina <= 20 then
            staminaFill.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        elseif stamina <= 50 then
            staminaFill.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
        else
            staminaFill.BackgroundColor3 = Color3.fromRGB(255, 222, 189)
        end

        if seekActive then
            staminaContainer.Visible = false
            stamina = math.min(maxStamina, stamina + 0.8)
            sprinting = false
        else
            staminaContainer.Visible = true
            if isExhausted then
                char:SetAttribute("SpeedBoost", 0)
                hum.WalkSpeed = 11
                stamina = math.min(maxStamina, stamina + 0.6)
                if breathSound and not breathSound.IsPlaying then breathSound:Play() end
                if stamina >= maxStamina then isExhausted = false end
            elseif crouching then
                char:SetAttribute("SpeedBoost", 0)
                hum.WalkSpeed = 7
                stamina = math.min(maxStamina, stamina + 0.9)
                if breathSound then breathSound:Stop() end
            elseif sprinting and isMoving and stamina > 5 then
                char:SetAttribute("SpeedBoost", 4.5)
                hum.WalkSpeed = 20
                stamina = math.max(0, stamina - 1.4)
                if stamina <= 0 then isExhausted = true end
                if breathSound then breathSound:Stop() end
            else
                char:SetAttribute("SpeedBoost", 0)
                hum.WalkSpeed = 14
                stamina = math.min(maxStamina, stamina + 0.7)
                if breathSound then breathSound:Stop() end
            end
        end
    end
end)

-- ============================================
-- UI, CAPTIONS, CREDITS
-- ============================================
local function ShowCaption(text, duration)
    local pGui = Player:WaitForChild("PlayerGui")
    if pGui:FindFirstChild("HardcoreCaption") then pGui.HardcoreCaption:Destroy() end
    local screenGui = Instance.new("ScreenGui", pGui)
    screenGui.Name = "HardcoreCaption"
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 999
    local captionLabel = Instance.new("TextLabel", screenGui)
    captionLabel.Size = UDim2.new(0.6, 0, 0.05, 10)
    captionLabel.Position = UDim2.new(0.5, 0, 0.92, -60)
    captionLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    captionLabel.BackgroundTransparency = 1
    captionLabel.Text = text
    captionLabel.TextColor3 = Color3.fromRGB(255, 222, 189)
    captionLabel.TextSize = 30
    captionLabel.Font = Enum.Font.Oswald
    captionLabel.TextStrokeTransparency = 0
    local alertSound = Instance.new("Sound", game.SoundService)
    alertSound.SoundId = "rbxassetid://3848738542"
    alertSound:Play()
    game.Debris:AddItem(alertSound, 2)
    task.delay(duration or 4, function()
        if captionLabel then
            TS:Create(captionLabel, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
            task.wait(0.5)
            pcall(function() screenGui:Destroy() end)
        end
    end)
end

local function ShowSmoothCredits()
    task.wait(3)
    local creditGui = Instance.new("ScreenGui", Player.PlayerGui)
    creditGui.Name = "HardcoreCredits"
    local creditLabel = Instance.new("TextLabel", creditGui)
    creditLabel.Text = "Original Hardcore By Noonie and Ping. | True Multiplayer Sync"
    creditLabel.Font = Enum.Font.Oswald
    creditLabel.TextSize = 22
    creditLabel.TextColor3 = Color3.fromRGB(255,255,255)
    creditLabel.TextStrokeTransparency = 0.5
    creditLabel.BackgroundTransparency = 1
    creditLabel.TextXAlignment = Enum.TextXAlignment.Left
    creditLabel.Position = UDim2.new(-0.6,0,0.05,0)
    creditLabel.Size = UDim2.new(0.5,0,0.05,0)
    TS:Create(creditLabel, TweenInfo.new(1.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0.02,0,0.05,0)}):Play()
    task.wait(5)
    local b = TS:Create(creditLabel, TweenInfo.new(1.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(-0.6,0,0.05,0)})
    b:Play()
    b.Completed:Connect(function() pcall(function() creditGui:Destroy() end) end)
end

pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Francisco1692qzd/OverridenEntitiesMode/refs/heads/main/nodes.lua"))()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/refs/heads/main/AddAchievements.lua"))()
end)

-- Door 0 check
local alreadyExecuted = workspace:FindFirstChild("ExecutedHard")
pcall(function()
    Player.PlayerGui.MainUI.Initiator.Main_Game.Health.Music.Blue.PlaybackSpeed = 0.55
    Player.PlayerGui.MainUI.Initiator.Main_Game.Health.Music.Blue.SoundId = "rbxassetid://10472612727"
end)
local GaveAchievement = false

if not alreadyExecuted then
    if LatestRoom.Value ~= 0 then
        ShowCaption("EXECUTOR: Error. Please go to Door 0 to begin.", 6)
        if Player.Character then Player.Character.Humanoid:TakeDamage(100) end
        return
    else
        local modeInit = Instance.new("BoolValue", workspace)
        modeInit.Name = "ExecutedHard"
        ShowCaption("EXECUTOR: Script Loaded. | True MP Sync: ON", 6)
    end
else
    ShowCaption("EXECUTOR: Already Running.", 3)
    return
end

-- ============================================
-- INITIALIZATION
-- ============================================
initSharedRandom()
CalculateSpawnDelays()
TryBecomeMaster()

local rammessages = {
    "Hardcore V5 by Noonie and Ping.",
    "TRUE MULTIPLAYER SYNC - All players see same spawns!",
    "Only Shocker is local (random per player)",
    "Ripper/Rebound/Frostbite: Timer + Door Required",
    "Cease/A60/Silence/DeerGod: Timer Only",
    "A-60 can spawn in room 50!",
    "Hold Q or tap sprint button to run!"
}

LatestRoom.Changed:Connect(function()
    if not opened and LatestRoom.Value == 1 then
        opened = true
        task.spawn(ShowSmoothCredits)
        ShowCaption("Hardcore Initiated. | True MP Sync: ON", 5)
        task.wait(3)
        ShowCaption("Have fun " .. Player.Name .. ".", 4)
        task.wait(7)
        ShowCaption(rammessages[math.random(1, #rammessages)], 5)
        CreateSprintButton()
        SetupMasterScheduler()
        SetupLocalSpawners()
        print("✅ Hardcore Mode Loaded! (Master: " .. (isMaster and "YES" or "NO") .. ")")
    end
end)

LatestRoom.Changed:Connect(function()
    if opened and LatestRoom.Value == 100 and not GaveAchievement then
        GaveAchievement = true
        pcall(function()
            local AchievementModule = Player.PlayerGui.MainUI.Initiator.Main_Game.RemoteListener.Modules.AchievementUnlock
            if AchievementModule then
                local unlockFunc = require(AchievementModule)
                unlockFunc(nil, "HardcoreSurvivor")
            end
        end)
    end
end)
