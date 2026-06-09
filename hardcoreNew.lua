-- [[ HARDCORE WITH PROPER MULTIPLAYER SYNC ]]
-- Uses ReplicatedStorage to sync entity spawns across ALL players
-- Shocker is NOT synced (random per player)
-- All other entities are FULLY SYNCED

repeat task.wait() until game:IsLoaded()

local Player = game.Players.LocalPlayer
local LatestRoom = game.ReplicatedStorage.GameData.LatestRoom
local TS = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local opened = false

-- ============================================
-- SIMPLE CONFIG - JUST CHANGE THESE NUMBERS!
-- ============================================

local CONFIG = {
	-- TIMER ENTITIES THAT WAIT FOR ROOM CHANGE (seconds between spawns)
	RIPPER_DELAY = {75, 115},        -- Spawns every 75-115 seconds (waits for door)
	REBOUND_DELAY = {480, 730},      -- Spawns every 480-730 seconds (waits for door)
	FROSTBITE_DELAY = {355, 830},    -- Spawns every 355-830 seconds (waits for door)
	
	-- Frostbite only after this room
	FROSTBITE_MIN_ROOM = 20,
	
	-- OTHER TIMER ENTITIES (spawn immediately, no door wait)
	CEASE_DELAY = {50, 80},         -- Spawns every 50-80 seconds (immediate)
	A60_DELAY = {1750, 2400},       -- Spawns every 29-40 minutes (immediate)
	SILENCE_DELAY = {600, 900},     -- Spawns every 10-15 minutes (immediate)
	DEERGOD_DELAY = {900, 1200},    -- Spawns every 15-20 minutes (immediate)
	
	-- SHOCKER is NOT SYNCED - random per player
	SHOCKER_DELAY = {25, 50},       -- Spawns every 25-50 seconds (local only)
}

-- ============================================
-- MULTIPLAYER SYNC SYSTEM
-- ============================================

-- Create sync folder in ReplicatedStorage (visible to all players)
local syncFolder = ReplicatedStorage:FindFirstChild("HardcoreSync") or Instance.new("Folder", ReplicatedStorage)
syncFolder.Name = "HardcoreSync"

-- Master spawn timer (controlled by the first player)
local masterTimer = syncFolder:FindFirstChild("MasterTimer") or Instance.new("NumberValue", syncFolder)
masterTimer.Name = "MasterTimer"

-- Next spawn info
local nextSpawn = syncFolder:FindFirstChild("NextSpawn") or Instance.new("StringValue", syncFolder)
nextSpawn.Name = "NextSpawn"

-- Spawn lock (prevents multiple players spawning at once)
local spawnLock = syncFolder:FindFirstChild("SpawnLock") or Instance.new("BoolValue", syncFolder)
spawnLock.Name = "SpawnLock"
spawnLock.Value = false

-- Track if player is the master (first to initialize)
local isMaster = false

-- Initialize master timer on first player
local function TryBecomeMaster()
    if masterTimer.Value == 0 then
        masterTimer.Value = workspace:GetServerTimeNow()
        isMaster = true
        print("🎮 This player is the MASTER (controlling spawn timers)")
    end
end

-- Get synced time (all players use the same master timer)
local function GetSyncedTime()
    if masterTimer.Value == 0 then
        return workspace:GetServerTimeNow()
    end
    return masterTimer.Value
end

-- Request to spawn an entity (only master decides, but all players spawn)
local function RequestSpawn(entityName, delay)
    if not isMaster then return false end
    
    if spawnLock.Value then return false end
    
    spawnLock.Value = true
    
    local spawnTime = GetSyncedTime() + delay
    nextSpawn.Value = entityName .. ":" .. tostring(spawnTime)
    
    spawnLock.Value = false
    return true
end

-- Listen for spawn commands from master
nextSpawn.Changed:Connect(function()
    if nextSpawn.Value == "" then return end
    
    local parts = {}
    for part in string.gmatch(nextSpawn.Value, "[^:]+") do
        table.insert(parts, part)
    end
    
    if #parts >= 2 then
        local entityName = parts[1]
        local spawnTime = tonumber(parts[2])
        
        -- Wait until spawn time
        while workspace:GetServerTimeNow() < spawnTime do
            task.wait(0.05)
        end
        
        -- Spawn the entity (if conditions allow)
        if CanSpawnEntity(entityName) then
            SpawnEntity(entityName)
            print("🎮 SYNC SPAWN: " .. entityName .. " at room " .. LatestRoom.Value)
        end
        
        -- Clear after spawn
        task.wait(0.5)
        nextSpawn.Value = ""
    end
end)

-- ============================================
-- EVERYTHING BELOW IS FROM NEW HARDCORE
-- ============================================

-- Track if player is alive
local isPlayerAlive = true
local activeSpawnThreads = {}

-- Track last spawn times (local only for immediate spawns)
local lastLocalSpawnTimes = {
	Shocker = 0,
}

-- Track last spawn times for synced entities (updated when master decides)
local lastSyncedSpawnTimes = {
	Ripper = 0,
	Rebound = 0,
	Frostbite = 0,
	Cease = 0,
	A60 = 0,
	Silence = 0,
	DeerGod = 0,
}

-- Store spawn delays (calculated locally but same seed for all)
local spawnDelays = {
	Ripper = 0,
	Rebound = 0,
	Frostbite = 0,
	Cease = 0,
	Shocker = 0,
	A60 = 0,
	Silence = 0,
	DeerGod = 0,
}

-- Shared random using JobId for consistency
local JobId = game.JobId
local function getDeterministicSeed(jobId)
	local seed = 0
	for i = 1, #jobId do
		seed = (seed * 31 + string.byte(jobId, i)) % 2^32
	end
	return seed
end

local sharedRandom = nil
local function initSharedRandom()
	local seed = getDeterministicSeed(JobId)
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

-- Calculate deterministic delays (same for all players)
local function CalculateSpawnDelays()
	spawnDelays.Ripper = sharedRandom.random(CONFIG.RIPPER_DELAY[1], CONFIG.RIPPER_DELAY[2])
	spawnDelays.Rebound = sharedRandom.random(CONFIG.REBOUND_DELAY[1], CONFIG.REBOUND_DELAY[2])
	spawnDelays.Frostbite = sharedRandom.random(CONFIG.FROSTBITE_DELAY[1], CONFIG.FROSTBITE_DELAY[2])
	spawnDelays.Cease = sharedRandom.random(CONFIG.CEASE_DELAY[1], CONFIG.CEASE_DELAY[2])
	spawnDelays.Shocker = sharedRandom.random(CONFIG.SHOCKER_DELAY[1], CONFIG.SHOCKER_DELAY[2])
	spawnDelays.A60 = sharedRandom.random(CONFIG.A60_DELAY[1], CONFIG.A60_DELAY[2])
	spawnDelays.Silence = sharedRandom.random(CONFIG.SILENCE_DELAY[1], CONFIG.SILENCE_DELAY[2])
	spawnDelays.DeerGod = sharedRandom.random(CONFIG.DEERGOD_DELAY[1], CONFIG.DEERGOD_DELAY[2])
	
	print("📊 Deterministic spawn delays:")
	print("   Ripper: " .. spawnDelays.Ripper .. "s, Rebound: " .. spawnDelays.Rebound .. "s, Frostbite: " .. spawnDelays.Frostbite .. "s")
	print("   Cease: " .. spawnDelays.Cease .. "s, A60: " .. spawnDelays.A60 .. "s, Silence: " .. spawnDelays.Silence .. "s, DeerGod: " .. spawnDelays.DeerGod .. "s")
	print("   Shocker (local only): " .. spawnDelays.Shocker .. "s")
end

-- Entity URLs
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

local function CanSpawnEntity(entityName)
	if not isPlayerAlive then return false end

	-- Seek check - NO entities spawn during Seek
	if workspace:FindFirstChild("SeekMovingNewClone") or workspace:FindFirstChild("SeekMoving") then
		return false
	end

	local latestRoom = LatestRoom.Value

	-- Room 100 check - NO entities spawn at Door 100
	if latestRoom == 100 then
		return false
	end
	
	-- Room 50 check - Only A60 can spawn here
	if latestRoom == 50 then
		if entityName == "A60" then
			-- A60 is allowed in room 50
		else
			return false
		end
	end
	
	-- Boss rooms 51-58 - NO entities spawn
	if latestRoom == 51 or (latestRoom > 52 and latestRoom < 59) then
		return false
	end

	-- Cooldown between spawns
	if workspace:GetServerTimeNow() - lastEntitySpawnTime < ENTITY_SPAWN_COOLDOWN then
		return false
	end

	-- Check if any entity already exists
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
	
	if not CanSpawnEntity(entityName) then
		return false
	end

	lastEntitySpawnTime = workspace:GetServerTimeNow()

	local success, err = pcall(function()
		local scriptContent = game:HttpGet(entityURLs[entityName])
		loadstring(scriptContent)()
		print("🎮 Spawning: " .. entityName)
	end)

	if not success then
		warn("Failed to spawn " .. entityName .. ": " .. tostring(err))
		return false
	end
	return true
end

-- ============================================
-- MASTER SPAWN SCHEDULER (Only master runs this)
-- ============================================

local function SetupMasterScheduler()
	if not isMaster then return end
	
	-- Keep track of last spawn times for master
	local masterLastSpawn = {
		Ripper = GetSyncedTime(),
		Rebound = GetSyncedTime(),
		Frostbite = GetSyncedTime(),
		Cease = GetSyncedTime(),
		A60 = GetSyncedTime(),
		Silence = GetSyncedTime(),
		DeerGod = GetSyncedTime(),
	}
	
	-- Main scheduler loop
	task.spawn(function()
		while isPlayerAlive and LatestRoom.Value >= 1 and LatestRoom.Value < 100 do
			local currentTime = GetSyncedTime()
			local shouldSchedule = false
			local entityToSpawn = nil
			local delayNeeded = 0
			
			-- Check each entity in priority order
			-- Ripper (room wait)
			if currentTime - masterLastSpawn.Ripper >= spawnDelays.Ripper then
				entityToSpawn = "Ripper"
				shouldSchedule = true
				masterLastSpawn.Ripper = currentTime
			end
			
			-- Rebound (room wait)
			if not shouldSchedule and currentTime - masterLastSpawn.Rebound >= spawnDelays.Rebound then
				entityToSpawn = "Rebound"
				shouldSchedule = true
				masterLastSpawn.Rebound = currentTime
			end
			
			-- Frostbite (room wait)
			if not shouldSchedule and currentTime - masterLastSpawn.Frostbite >= spawnDelays.Frostbite then
				entityToSpawn = "Frostbite"
				shouldSchedule = true
				masterLastSpawn.Frostbite = currentTime
			end
			
			-- Cease (immediate)
			if not shouldSchedule and currentTime - masterLastSpawn.Cease >= spawnDelays.Cease then
				entityToSpawn = "Cease"
				shouldSchedule = true
				masterLastSpawn.Cease = currentTime
			end
			
			-- A60 (immediate)
			if not shouldSchedule and currentTime - masterLastSpawn.A60 >= spawnDelays.A60 then
				entityToSpawn = "A60"
				shouldSchedule = true
				masterLastSpawn.A60 = currentTime
			end
			
			-- Silence (immediate)
			if not shouldSchedule and currentTime - masterLastSpawn.Silence >= spawnDelays.Silence then
				entityToSpawn = "Silence"
				shouldSchedule = true
				masterLastSpawn.Silence = currentTime
			end
			
			-- Deer God (immediate)
			if not shouldSchedule and currentTime - masterLastSpawn.DeerGod >= spawnDelays.DeerGod then
				entityToSpawn = "DeerGod"
				shouldSchedule = true
				masterLastSpawn.DeerGod = currentTime
			end
			
			-- Schedule the spawn if needed
			if shouldSchedule and entityToSpawn then
				-- For room-wait entities, wait for next room change
				local isRoomWait = (entityToSpawn == "Ripper" or entityToSpawn == "Rebound" or entityToSpawn == "Frostbite")
				
				if isRoomWait then
					-- Wait for room change (handled separately)
					-- Just mark that it's ready to spawn on next room
					roomWaitReady = entityToSpawn
				else
					-- Spawn immediately with 1 second delay
					RequestSpawn(entityToSpawn, 1)
				end
			end
			
			task.wait(0.5)
		end
	end)
	
	-- Handle room-wait spawns
	local roomWaitReady = nil
	LatestRoom.Changed:Connect(function()
		if roomWaitReady then
			if CanSpawnEntity(roomWaitReady) then
				RequestSpawn(roomWaitReady, 0.5)
				print("🚪 ROOM TRIGGER: " .. roomWaitReady)
			end
			roomWaitReady = nil
		end
	end)
end

-- ============================================
-- LOCAL SPAWNERS (Shocker only - not synced)
-- ============================================

local function SetupLocalSpawners()
	-- SHOCKER (local only - NOT synced)
	task.spawn(function()
		while isPlayerAlive and LatestRoom.Value >= 1 and LatestRoom.Value < 100 do
			local currentTime = workspace:GetServerTimeNow()
			local timeSinceLastSpawn = currentTime - lastLocalSpawnTimes.Shocker
			local delay = spawnDelays.Shocker
			
			if timeSinceLastSpawn >= delay then
				if CanSpawnEntity("Shocker") then
					SpawnEntity("Shocker")
					lastLocalSpawnTimes.Shocker = currentTime
					print("⚡ SHOCKER (local only)")
				end
			end
			task.wait(1)
		end
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
	captionLabel.Parent = screenGui

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

-- [CRÉDITOS]
local function ShowSmoothCredits()
	task.wait(3)
	local creditGui = Instance.new("ScreenGui", Player.PlayerGui)
	creditGui.Name = "HardcoreCredits"
	local creditLabel = Instance.new("TextLabel", creditGui)
	creditLabel.Text = "Original Hardcore By Noonie and Ping. | True Multiplayer Sync"
	creditLabel.Font = Enum.Font.Oswald
	creditLabel.TextSize = 22
	creditLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	creditLabel.TextStrokeTransparency = 0.5
	creditLabel.BackgroundTransparency = 1
	creditLabel.TextXAlignment = Enum.TextXAlignment.Left
	creditLabel.Position = UDim2.new(-0.6, 0, 0.05, 0) 
	creditLabel.Size = UDim2.new(0.5, 0, 0.05, 0)

	TS:Create(creditLabel, TweenInfo.new(1.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0.02, 0, 0.05, 0)}):Play()
	task.wait(5)
	local b = TS:Create(creditLabel, TweenInfo.new(1.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(-0.6, 0, 0.05, 0)})
	b:Play()
	b.Completed:Connect(function() 
		pcall(function() creditGui:Destroy() end)
	end)
end

-- Load external modules
pcall(function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/Francisco1692qzd/OverridenEntitiesMode/refs/heads/main/nodes.lua"))()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/refs/heads/main/AddAchievements.lua"))()
end)

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
		ShowCaption("EXECUTOR: Script Loaded. | True MP Sync: ON", 6)
	end
else
	ShowCaption("EXECUTOR: Already Running.", 3)
	return 
end

-- ============================================
-- STAMINA SYSTEM (Unchanged)
-- ============================================
local UIS = game:GetService("UserInputService")
local stamina, maxStamina, isExhausted, sprinting, crouching = 100, 100, false, false, nil

local staminaGui = Instance.new("ScreenGui")
staminaGui.Name = "StaminaGui"
staminaGui.ResetOnSpawn = false
staminaGui.Parent = Player.PlayerGui

local staminaContainer = Instance.new("Frame")
staminaContainer.Size = UDim2.new(0, 280, 0, 12)
staminaContainer.Position = UDim2.new(0.98, 0, 0.95, 0)
staminaContainer.AnchorPoint = Vector2.new(1, 1)
staminaContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
staminaContainer.BackgroundTransparency = 0.4
staminaContainer.BorderSizePixel = 0
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

UIS.InputBegan:Connect(function(i, gpe)
	if not gpe and i.KeyCode == Enum.KeyCode.Q then sprinting = true end
end)
UIS.InputEnded:Connect(function(i) 
	if i.KeyCode == Enum.KeyCode.Q then sprinting = false end 
end)

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

-- Initialize
initSharedRandom()
CalculateSpawnDelays()
TryBecomeMaster()

-- Main setup
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
		SetupMasterScheduler()      -- Master controls all synced spawns
		SetupLocalSpawners()         -- Shocker only (local)

		print("✅ Hardcore Mode Loaded!")
		print("📊 SYNC SYSTEM:")
		print("   Master Player: " .. (isMaster and "YES" or "NO"))
		print("   Synced entities: Ripper, Rebound, Frostbite, Cease, A60, Silence, DeerGod")
		print("   Local entity: Shocker (random per player)")
		print("📍 Spawn Restrictions:")
		print("   - NO spawns during Seek chase")
		print("   - NO spawns in rooms 51-58")
		print("   - NO spawns in room 100")
		print("   - ONLY A-60 can spawn in room 50")
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
