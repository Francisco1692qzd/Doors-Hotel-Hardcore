-- [[ OLD HARDCORE SYNC SYSTEM WITH NEW TIMER CONFIG ]]
-- Uses SyncWait for multiplayer synchronization

repeat task.wait() until game:IsLoaded()

local Player = game.Players.LocalPlayer
local LatestRoom = game.ReplicatedStorage.GameData.LatestRoom
local TS = game:GetService("TweenService")

-- ============================================
-- SIMPLE CONFIG - JUST CHANGE THESE NUMBERS!
-- ============================================

local CONFIG = {
	-- TIMER ENTITIES (seconds between spawns)
	-- These spawn on timers, but check on every room change
	RIPPER_DELAY = {75, 105},        -- Spawns every 75-105 seconds
	REBOUND_DELAY = {365, 540},      -- Spawns every 365-540 seconds
	FROSTBITE_DELAY = {355, 830},    -- Spawns every 355-830 seconds
	
	-- Frostbite only after this room
	FROSTBITE_MIN_ROOM = 20,
	
	-- Other timer entities (seconds)
	CEASE_DELAY = {50, 80},
	SHOCKER_DELAY = {25, 50},
	A60_DELAY = {300, 500},
	SILENCE_DELAY = {600, 900},
	DEERGOD_DELAY = {900, 1200},
}

-- ============================================
-- DO NOT EDIT BELOW
-- ============================================

-- [SINCRONIA - OLD SYSTEM]
local startTimeValue = workspace:FindFirstChild("OldHardcoreStartTime") or Instance.new("NumberValue", workspace)
startTimeValue.Name = "OldHardcoreStartTime"

local function SyncWait(seconds)
    if startTimeValue.Value == 0 then return end
    local targetTime = startTimeValue.Value + seconds
    while workspace:GetServerTimeNow() < targetTime do task.wait(0.5) end
end

-- Track if player is alive
local isPlayerAlive = true
local activeSpawnThreads = {}

-- Track last spawn times
local lastSpawnTimes = {
	Ripper = 0,
	Rebound = 0,
	Frostbite = 0,
}

-- Store spawn delays
local spawnDelays = {
	Ripper = 0,
	Rebound = 0,
	Frostbite = 0,
}

-- Shared random for deterministic spawns
local sharedRandom = nil
local function initSharedRandom()
    local seed = 0
    local JobId = game.JobId
    for i = 1, #JobId do
        seed = (seed * 31 + string.byte(JobId, i)) % 2^32
    end
    math.randomseed(seed)
    sharedRandom = {
        random = function(a, b)
            if b then return math.random(a, b)
            elseif a then return math.random(a)
            else return math.random() end
        end
    }
    return sharedRandom
end

-- Calculate deterministic delays
local function CalculateSpawnDelays()
    spawnDelays.Ripper = sharedRandom.random(CONFIG.RIPPER_DELAY[1], CONFIG.RIPPER_DELAY[2])
    spawnDelays.Rebound = sharedRandom.random(CONFIG.REBOUND_DELAY[1], CONFIG.REBOUND_DELAY[2])
    spawnDelays.Frostbite = sharedRandom.random(CONFIG.FROSTBITE_DELAY[1], CONFIG.FROSTBITE_DELAY[2])
    
    print("📊 Deterministic spawn delays:")
    print("   Ripper: " .. spawnDelays.Ripper .. " seconds")
    print("   Rebound: " .. spawnDelays.Rebound .. " seconds")
    print("   Frostbite: " .. spawnDelays.Frostbite .. " seconds")
end

-- Entity URLs (NEW - using Doors-Hotel-Hardcore)
local entityURLs = {
    Ripper = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/refs/heads/main/ripper.lua",
    Rebound = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/refs/heads/main/rebound.lua",
    DeerGod = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/refs/heads/main/deergod.lua",
    Cease = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/refs/heads/main/cease.lua",
    Shocker = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/refs/heads/main/shocker.lua",
    Silence = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/refs/heads/main/silence.lua",
    A60 = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/refs/heads/main/a60.lua",
    Frostbite = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/refs/heads/main/frostbite.lua"
}

local lastEntitySpawnTime = 0
local ENTITY_SPAWN_COOLDOWN = 3

local function CanSpawnEntity()
    if not isPlayerAlive then return false end
    if workspace:FindFirstChild("SeekMovingNewClone") or workspace:FindFirstChild("SeekMoving") then
        return false
    end
    local latestRoom = LatestRoom.Value
    if latestRoom == 51 or (latestRoom > 52 and latestRoom < 59) then
        return false
    end
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
    lastEntitySpawnTime = workspace:GetServerTimeNow()
    lastSpawnTimes[entityName] = workspace:GetServerTimeNow()
    local success, err = pcall(function()
        local scriptContent = game:HttpGet(entityURLs[entityName])
        loadstring(scriptContent)()
        print("🎮 Spawning: " .. entityName .. " at room " .. LatestRoom.Value)
    end)
    if not success then
        warn("Failed to spawn " .. entityName .. ": " .. tostring(err))
        return false
    end
    return true
end

-- Check and spawn timer-based entities on room change
local function CheckAndSpawnTimerEntities(currentRoom)
    local currentTime = workspace:GetServerTimeNow()
    
    -- Check Ripper
    if currentTime - lastSpawnTimes.Ripper >= spawnDelays.Ripper then
        if CanSpawnEntity() then
            SpawnEntity("Ripper")
            print("🔪 RIPPER - Room " .. currentRoom)
            return
        end
    end
    
    -- Check Rebound
    if currentTime - lastSpawnTimes.Rebound >= spawnDelays.Rebound then
        if CanSpawnEntity() then
            SpawnEntity("Rebound")
            print("🔄 REBOUND - Room " .. currentRoom)
            return
        end
    end
    
    -- Check Frostbite (only after min room)
    if currentRoom >= CONFIG.FROSTBITE_MIN_ROOM then
        if currentTime - lastSpawnTimes.Frostbite >= spawnDelays.Frostbite then
            if CanSpawnEntity() then
                SpawnEntity("Frostbite")
                print("❄️ FROSTBITE - Room " .. currentRoom)
                return
            end
        end
    end
end

-- TIMER-BASED SPAWNERS (Cease, Shocker, A60, Silence, Deer God)
local function SetupIndependentTimerSpawners()
    -- CEASE
    local ceaseDelay = sharedRandom.random(CONFIG.CEASE_DELAY[1], CONFIG.CEASE_DELAY[2])
    local lastCeaseSpawn = workspace:GetServerTimeNow()
    task.spawn(function()
        while isPlayerAlive and LatestRoom.Value >= 1 and LatestRoom.Value < 100 do
            local currentTime = workspace:GetServerTimeNow()
            if currentTime - lastCeaseSpawn >= ceaseDelay then
                if CanSpawnEntity() and isPlayerAlive then
                    SpawnEntity("Cease")
                    lastCeaseSpawn = currentTime
                    ceaseDelay = sharedRandom.random(CONFIG.CEASE_DELAY[1], CONFIG.CEASE_DELAY[2])
                end
            end
            task.wait(1)
        end
    end)

    -- SHOCKER
    local shockerDelay = sharedRandom.random(CONFIG.SHOCKER_DELAY[1], CONFIG.SHOCKER_DELAY[2])
    local lastShockerSpawn = workspace:GetServerTimeNow()
    task.spawn(function()
        while isPlayerAlive and LatestRoom.Value >= 1 and LatestRoom.Value < 100 do
            local currentTime = workspace:GetServerTimeNow()
            if currentTime - lastShockerSpawn >= shockerDelay then
                if CanSpawnEntity() and isPlayerAlive then
                    SpawnEntity("Shocker")
                    lastShockerSpawn = currentTime
                    shockerDelay = sharedRandom.random(CONFIG.SHOCKER_DELAY[1], CONFIG.SHOCKER_DELAY[2])
                end
            end
            task.wait(1)
        end
    end)

    -- A60
    local a60Delay = sharedRandom.random(CONFIG.A60_DELAY[1], CONFIG.A60_DELAY[2])
    local lastA60Spawn = workspace:GetServerTimeNow()
    task.spawn(function()
        while isPlayerAlive and LatestRoom.Value >= 1 and LatestRoom.Value < 100 do
            local currentTime = workspace:GetServerTimeNow()
            if currentTime - lastA60Spawn >= a60Delay then
                if CanSpawnEntity() and isPlayerAlive then
                    SpawnEntity("A60")
                    lastA60Spawn = currentTime
                    a60Delay = sharedRandom.random(CONFIG.A60_DELAY[1], CONFIG.A60_DELAY[2])
                end
            end
            task.wait(1)
        end
    end)

    -- SILENCE
    local silenceDelay = sharedRandom.random(CONFIG.SILENCE_DELAY[1], CONFIG.SILENCE_DELAY[2])
    local lastSilenceSpawn = workspace:GetServerTimeNow()
    task.spawn(function()
        while isPlayerAlive and LatestRoom.Value >= 1 and LatestRoom.Value < 100 do
            local currentTime = workspace:GetServerTimeNow()
            if currentTime - lastSilenceSpawn >= silenceDelay then
                if CanSpawnEntity() and isPlayerAlive then
                    SpawnEntity("Silence")
                    lastSilenceSpawn = currentTime
                    silenceDelay = sharedRandom.random(CONFIG.SILENCE_DELAY[1], CONFIG.SILENCE_DELAY[2])
                end
            end
            task.wait(1)
        end
    end)

    -- DEER GOD
    local deergodDelay = sharedRandom.random(CONFIG.DEERGOD_DELAY[1], CONFIG.DEERGOD_DELAY[2])
    local lastDeergodSpawn = workspace:GetServerTimeNow()
    task.spawn(function()
        while isPlayerAlive and LatestRoom.Value >= 1 and LatestRoom.Value < 100 do
            local currentTime = workspace:GetServerTimeNow()
            if currentTime - lastDeergodSpawn >= deergodDelay then
                if CanSpawnEntity() and isPlayerAlive then
                    SpawnEntity("DeerGod")
                    lastDeergodSpawn = currentTime
                    deergodDelay = sharedRandom.random(CONFIG.DEERGOD_DELAY[1], CONFIG.DEERGOD_DELAY[2])
                end
            end
            task.wait(1)
        end
    end)
end

-- ROOM CHANGE HANDLER
local function SetupRoomHandler()
    local lastRoom = 0
    
    LatestRoom.Changed:Connect(function()
        if not opened then return end
        if not isPlayerAlive then return end

        local currentRoom = LatestRoom.Value

        -- Skip boss rooms
        if currentRoom == 50 or currentRoom == 51 or (currentRoom > 52 and currentRoom < 59) then
            return
        end

        if currentRoom <= 1 then
            return
        end

        -- Prevent duplicate events
        if currentRoom == lastRoom then
            return
        end

        lastRoom = currentRoom
        
        -- Check and spawn timer-based entities
        CheckAndSpawnTimerEntities(currentRoom)
    end)
end

-- [SISTEMA DE LEGENDAS]
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
            task.wait(0.5) screenGui:Destroy()
        end
    end)
end

-- [CRÉDITOS]
local function ShowSmoothCredits()
    task.wait(3)
    local creditGui = Instance.new("ScreenGui", Player.PlayerGui)
    creditGui.Name = "HardcoreCredits"
    local creditLabel = Instance.new("TextLabel", creditGui)
    creditLabel.Text = "Original Hardcore By Noonie and Ping."
    creditLabel.Font = Enum.Font.Oswald
    creditLabel.TextSize = 22
    creditLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    creditLabel.TextStrokeTransparency = 0.5
    creditLabel.BackgroundTransparency = 1
    creditLabel.TextXAlignment = Enum.TextXAlignment.Left
    creditLabel.Position = UDim2.new(-0.6, 0, 0.05, 0) 
    creditLabel.Size = UDim2.new(0.4, 0, 0.05, 0)

    local slideIn = TS:Create(creditLabel, TweenInfo.new(1.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.02, 0, 0.05, 0)
    })
    
    local slideBack = TS:Create(creditLabel, TweenInfo.new(1.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Position = UDim2.new(-0.6, 0, 0.05, 0)
    })

    slideIn:Play()
    task.wait(5)
    slideBack:Play()
    
    slideBack.Completed:Connect(function()
        creditGui:Destroy()
    end)
end

-- [DOOR 0 LOCK]
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
        ShowCaption("EXECUTOR: Script Loaded.", 6)
    end
else
    ShowCaption("EXECUTOR: Already Running.", 3)
    return 
end

-- ============================================
-- STAMINA SYSTEM
-- ============================================
local UIS = game:GetService("UserInputService")
local stamina, maxStamina, isExhausted, sprinting, crouching = 100, 100, false, false, false

local sg = Instance.new("ScreenGui", Player.PlayerGui)
sg.Name = "StaminaGui"
sg.ResetOnSpawn = false
local container = Instance.new("Frame", sg)
container.Size = UDim2.new(0, 250, 0, 10)
container.Position = UDim2.new(0.98, 0, 0.95, 0)
container.AnchorPoint = Vector2.new(1, 1)
container.BackgroundColor3 = Color3.new(0, 0, 0)
container.BackgroundTransparency = 0.4
local bar = Instance.new("Frame", container)
bar.Size = UDim2.new(1, 0, 1, 0)
bar.BackgroundColor3 = Color3.fromRGB(255, 222, 189)
Instance.new("UIStroke", container).Thickness = 1.5

local mobileBtn
if UIS.TouchEnabled then
    mobileBtn = Instance.new("ImageButton", sg)
    mobileBtn.Size = UDim2.new(0, 80, 0, 80)
    mobileBtn.Position = UDim2.new(0.85, 0, 0.80, 0)
    mobileBtn.BackgroundColor3 = Color3.new(0,0,0)
    mobileBtn.BackgroundTransparency = 0.5
    mobileBtn.Image = "rbxassetid://89190879948216"
    Instance.new("UICorner", mobileBtn).CornerRadius = UDim.new(1,0)
    mobileBtn.MouseButton1Down:Connect(function() sprinting = true end)
    mobileBtn.MouseButton1Up:Connect(function() sprinting = false end)
end

UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.KeyCode == Enum.KeyCode.Q then sprinting = true 
    elseif i.KeyCode == Enum.KeyCode.C or i.KeyCode == Enum.KeyCode.LeftControl then crouching = not crouching end
end)
UIS.InputEnded:Connect(function(i) if i.KeyCode == Enum.KeyCode.Q then sprinting = false end end)

local breathSound
local function SetupCharacter(char)
    local head = char:WaitForChild("Head")
    breathSound = Instance.new("Sound", head)
    breathSound.SoundId = "rbxassetid://8258601891"
    breathSound.Volume = 2.3
    breathSound.Looped = true
end
Player.CharacterAdded:Connect(SetupCharacter)
if Player.Character then SetupCharacter(Player.Character) end

task.spawn(function()
    while task.wait(0.05) do
        local char = Player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if not hum then continue end
        local isMoving = hum.MoveDirection.Magnitude > 0
        local seekActive = workspace:FindFirstChild("SeekMoving")

        if seekActive then
            container.Visible = false
            stamina = 100
        else
            container.Visible = true
            if isExhausted then
                char:SetAttribute("SpeedBoost", 0)
                hum.WalkSpeed = 11
                stamina = math.min(100, stamina + 0.4)
                bar.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                if breathSound and not breathSound.IsPlaying then breathSound:Play() end
                if stamina >= 100 then isExhausted = false end
            elseif crouching then
                char:SetAttribute("SpeedBoost", 0)
                hum.WalkSpeed = 7
                stamina = math.min(100, stamina + 0.8)
            elseif sprinting and isMoving and stamina > 5 then
                char:SetAttribute("SpeedBoost", 4)
                hum.WalkSpeed = 19
                stamina = math.max(0, stamina - 1.2)
                if stamina <= 0 then isExhausted = true end
            else
                char:SetAttribute("SpeedBoost", 0)
                hum.WalkSpeed = 13
                stamina = math.min(100, stamina + 0.5)
                bar.BackgroundColor3 = Color3.fromRGB(255, 222, 189)
                if breathSound then breathSound:Stop() end
            end
            bar.Size = UDim2.new(stamina / 100, 0, 1, 0)
        end
    end
end)

-- Initialize shared random
initSharedRandom()
CalculateSpawnDelays()

-- Main setup
local opened = false
LatestRoom.Changed:Connect(function()
    if not opened and LatestRoom.Value == 1 then
        opened = true
        startTimeValue.Value = workspace:GetServerTimeNow()
        
        -- Initialize last spawn times
        local startTime = workspace:GetServerTimeNow()
        lastSpawnTimes.Ripper = startTime
        lastSpawnTimes.Rebound = startTime
        lastSpawnTimes.Frostbite = startTime

        task.spawn(ShowSmoothCredits)
        ShowCaption("Hardcore Initiated. | Timer Sync: ON", 5)
        task.wait(3)
        ShowCaption("Have fun " .. Player.Name .. ".", 4)
        task.wait(4)
        ShowCaption("Stamina and Mobile support ready.", 5)
        task.wait(5)
        
        SetupRoomHandler()
        SetupIndependentTimerSpawners()

        print("✅ Hardcore Mode Loaded!")
        print("📊 TIMER CONFIG:")
        print("   Ripper: " .. CONFIG.RIPPER_DELAY[1] .. "-" .. CONFIG.RIPPER_DELAY[2] .. " seconds")
        print("   Rebound: " .. CONFIG.REBOUND_DELAY[1] .. "-" .. CONFIG.REBOUND_DELAY[2] .. " seconds")
        print("   Frostbite: " .. CONFIG.FROSTBITE_DELAY[1] .. "-" .. CONFIG.FROSTBITE_DELAY[2] .. " seconds")
    end
end)

-- Achievement on Door 100
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
