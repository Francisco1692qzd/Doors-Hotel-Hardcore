-- [[ NEW HARDCORE WITH OLD SYNCWAIT MULTIPLAYER SYSTEM ]]
-- Ripper/Rebound/Frostbite: Timer + Room Change
-- Other entities: Timer only (spawn immediately)

repeat task.wait() until game:IsLoaded()

local Player = game.Players.LocalPlayer
local LatestRoom = game.ReplicatedStorage.GameData.LatestRoom
local TS = game:GetService("TweenService")

local opened = false

-- ============================================
-- SIMPLE CONFIG - JUST CHANGE THESE NUMBERS!
-- ============================================

local CONFIG = {
	-- TIMER ENTITIES THAT WAIT FOR ROOM CHANGE (seconds between spawns)
	RIPPER_DELAY = {75, 115},        -- Spawns every 75-115 seconds (waits for door)
	REBOUND_DELAY = {480, 730},      -- Spawns every 365-540 seconds (waits for door)
	FROSTBITE_DELAY = {355, 830},    -- Spawns every 355-830 seconds (waits for door)
	
	-- Frostbite only after this room
	FROSTBITE_MIN_ROOM = 20,
	
	-- OTHER TIMER ENTITIES (spawn immediately, no door wait)
	CEASE_DELAY = {50, 80},         -- Spawns every 50-80 seconds (immediate)
	SHOCKER_DELAY = {25, 50},       -- Spawns every 25-50 seconds (immediate)
	A60_DELAY = {1750, 2400},       -- Spawns every 5-8 minutes (immediate)
	SILENCE_DELAY = {600, 900},     -- Spawns every 10-15 minutes (immediate)
	DEERGOD_DELAY = {900, 1200},    -- Spawns every 15-20 minutes (immediate)
}

-- ============================================
-- MULTIPLAYER SYNC - OLD SYSTEM (SyncWait)
-- ============================================

local startTimeValue = workspace:FindFirstChild("HardcoreStartTime") or Instance.new("NumberValue", workspace)
startTimeValue.Name = "HardcoreStartTime"

local function SyncWait(seconds)
    if startTimeValue.Value == 0 then return end
    local targetTime = startTimeValue.Value + seconds
    while workspace:GetServerTimeNow() < targetTime do task.wait(0.5) end
end

-- ============================================
-- EVERYTHING BELOW IS FROM NEW HARDCORE
-- ============================================

-- Get the server's unique JobId for deterministic random
local JobId = game.JobId
local function getDeterministicSeed(jobId)
	local seed = 0
	for i = 1, #jobId do
		seed = (seed * 31 + string.byte(jobId, i)) % 2^32
	end
	return seed
end

-- Create a deterministic random generator (SAME NUMBERS FOR ALL CLIENTS)
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
	print("🎮 Shared random seed: " .. seed)
	return sharedRandom
end

-- Track if player is alive
local isPlayerAlive = true
local activeSpawnThreads = {}

-- Track last spawn times
local lastSpawnTimes = {
	Ripper = 0,
	Rebound = 0,
	Frostbite = 0,
	Cease = 0,
	Shocker = 0,
	A60 = 0,
	Silence = 0,
	DeerGod = 0,
}

-- Store spawn delays
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

-- Calculate deterministic delays
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
	print("   Ripper (room wait): " .. spawnDelays.Ripper .. " seconds")
	print("   Rebound (room wait): " .. spawnDelays.Rebound .. " seconds")
	print("   Frostbite (room wait): " .. spawnDelays.Frostbite .. " seconds")
	print("   Cease (immediate): " .. spawnDelays.Cease .. " seconds")
	print("   Shocker (immediate): " .. spawnDelays.Shocker .. " seconds")
	print("   A60 (immediate): " .. spawnDelays.A60 .. " seconds")
	print("   Silence (immediate): " .. spawnDelays.Silence .. " seconds")
	print("   DeerGod (immediate): " .. spawnDelays.DeerGod .. " seconds")
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

local function CanSpawnEntity()
	if not isPlayerAlive then return false end

	if workspace:FindFirstChild("SeekMovingNewClone") or workspace:FindFirstChild("SeekMoving") then
		return false
	end

	local latestRoom = LatestRoom.Value

	if latestRoom == 50 or latestRoom == 51 or (latestRoom > 52 and latestRoom < 59) then
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

-- ============================================
-- ENTITIES THAT WAIT FOR ROOM CHANGE (Ripper, Rebound, Frostbite)
-- ============================================

local function CheckRoomWaitEntities(currentRoom)
	local currentTime = workspace:GetServerTimeNow()
	
	-- Check Ripper
	if currentTime - lastSpawnTimes.Ripper >= spawnDelays.Ripper then
		if CanSpawnEntity() and LatestRoom.Value ~= 50 or LatestRoom.Value ~= 100 then
			SpawnEntity("Ripper")
			ShowCaption("⚠️ Ripper is approaching...", 3)
			print("🔪 RIPPER - Room " .. currentRoom)
			return true
		end
	end
	
	-- Check Rebound
	if currentTime - lastSpawnTimes.Rebound >= spawnDelays.Rebound then
		if CanSpawnEntity() and LatestRoom.Value ~= 50 or LatestRoom.Value ~= 100 then
			SpawnEntity("Rebound")
			ShowCaption("⚠️ Rebound is approaching...", 3)
			print("🔄 REBOUND - Room " .. currentRoom)
			return true
		end
	end
	
	-- Check Frostbite (only after min room)
	if currentRoom >= CONFIG.FROSTBITE_MIN_ROOM then
		if currentTime - lastSpawnTimes.Frostbite >= spawnDelays.Frostbite then
			if CanSpawnEntity() and LatestRoom.Value ~= 50 or LatestRoom.Value ~= 100 then
				SpawnEntity("Frostbite")
				ShowCaption("⚠️ Frostbite is approaching...", 3)
				print("❄️ FROSTBITE - Room " .. currentRoom)
				return true
			end
		end
	end
	
	return false
end

-- ============================================
-- ENTITIES THAT SPAWN IMMEDIATELY (No room wait)
-- ============================================

local function SetupImmediateTimerSpawners()
	-- CEASE
	task.spawn(function()
		while isPlayerAlive and LatestRoom.Value >= 1 and LatestRoom.Value < 100 do
			local currentTime = workspace:GetServerTimeNow()
			local timeSinceLastSpawn = currentTime - lastSpawnTimes.Cease
			local delay = spawnDelays.Cease
			
			if timeSinceLastSpawn >= delay then
				if CanSpawnEntity() and isPlayerAlive and LatestRoom.Value ~= 50 or LatestRoom.Value ~= 100 then
					SpawnEntity("Cease")
					--ShowCaption("⚠️ Cease is approaching...", 3)
				end
			end
			task.wait(1)
		end
	end)

	-- SHOCKER
	task.spawn(function()
		while isPlayerAlive and LatestRoom.Value >= 1 and LatestRoom.Value < 100 do
			local currentTime = workspace:GetServerTimeNow()
			local timeSinceLastSpawn = currentTime - lastSpawnTimes.Shocker
			local delay = spawnDelays.Shocker
			
			if timeSinceLastSpawn >= delay then
				if CanSpawnEntity() and isPlayerAlive then
					SpawnEntity("Shocker")
					--ShowCaption("⚠️ Shocker is approaching...", 3)
				end
			end
			task.wait(1)
		end
	end)

	-- A60
	task.spawn(function()
		while isPlayerAlive and LatestRoom.Value >= 1 and LatestRoom.Value < 100 do
			local currentTime = workspace:GetServerTimeNow()
			local timeSinceLastSpawn = currentTime - lastSpawnTimes.A60
			local delay = spawnDelays.A60
			
			if timeSinceLastSpawn >= delay then
				if CanSpawnEntity() and isPlayerAlive then
					SpawnEntity("A60")
					--ShowCaption("⚠️ A-60 is approaching...", 3)
				end
			end
			task.wait(1)
		end
	end)

	-- SILENCE
	task.spawn(function()
		while isPlayerAlive and LatestRoom.Value >= 1 and LatestRoom.Value < 100 do
			local currentTime = workspace:GetServerTimeNow()
			local timeSinceLastSpawn = currentTime - lastSpawnTimes.Silence
			local delay = spawnDelays.Silence
			
			if timeSinceLastSpawn >= delay then
				if CanSpawnEntity() and isPlayerAlive then
					SpawnEntity("Silence")
					--ShowCaption("⚠️ Silence is approaching...", 3)
				end
			end
			task.wait(1)
		end
	end)

	-- DEER GOD
	task.spawn(function()
		while isPlayerAlive and LatestRoom.Value >= 1 and LatestRoom.Value < 100 do
			local currentTime = workspace:GetServerTimeNow()
			local timeSinceLastSpawn = currentTime - lastSpawnTimes.DeerGod
			local delay = spawnDelays.DeerGod
			
			if timeSinceLastSpawn >= delay then
				if CanSpawnEntity() and isPlayerAlive then
					SpawnEntity("DeerGod")
					--ShowCaption("⚠️ Deer God is approaching...", 3)
				end
			end
			task.wait(1)
		end
	end)
end

-- ROOM CHANGE HANDLER (Only for Ripper, Rebound, Frostbite)
local function SetupRoomHandler()
	local lastRoom = 0
	
	LatestRoom.Changed:Connect(function()
		if not opened then return end
		if not isPlayerAlive then return end

		local currentRoom = LatestRoom.Value

		-- Skip boss rooms
		if currentRoom == 51 or (currentRoom > 52 and currentRoom < 59) then
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
		
		-- Check only Ripper, Rebound, Frostbite (they wait for room change)
		CheckRoomWaitEntities(currentRoom)
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
	creditLabel.Text = "Original Hardcore By Noonie and Ping. | Deterministic Multiplayer Sync"
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
		ShowCaption("EXECUTOR: Script Loaded. | Deterministic MP Sync: ON", 6)
	end
else
	ShowCaption("EXECUTOR: Already Running.", 3)
	return 
end

-- ============================================
-- STAMINA SYSTEM
-- ============================================
local UIS = game:GetService("UserInputService")
local stamina, maxStamina, isExhausted, sprinting, crouching = 100, 100, false, false, nil

-- Stamina GUI
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

-- Desktop sprint (Q key)
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

-- Character setup
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

-- Stamina loop
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

-- Initialize shared random
initSharedRandom()
CalculateSpawnDelays()

-- Main setup
local rammessages = {
	"Hardcore V5 by Noonie and Ping.",
	"Deterministic MP Sync - All players see same spawns!",
	"Ripper/Rebound/Frostbite: Timer + Door Required",
	"Cease/Shocker/A60/Silence/DeerGod: Timer Only",
	"Hold Q or tap sprint button to run!"
}

LatestRoom.Changed:Connect(function()
	if not opened and LatestRoom.Value == 1 then
		opened = true
		startTimeValue.Value = workspace:GetServerTimeNow()
		
		-- Initialize all last spawn times to start time
		local startTime = workspace:GetServerTimeNow()
		lastSpawnTimes.Ripper = startTime
		lastSpawnTimes.Rebound = startTime
		lastSpawnTimes.Frostbite = startTime
		lastSpawnTimes.Cease = startTime
		lastSpawnTimes.Shocker = startTime
		lastSpawnTimes.A60 = startTime
		lastSpawnTimes.Silence = startTime
		lastSpawnTimes.DeerGod = startTime

		task.spawn(ShowSmoothCredits)
		ShowCaption("Hardcore Initiated. | Deterministic MP Sync: ON", 5)
		task.wait(3)
		ShowCaption("Have fun " .. Player.Name .. ".", 4)
		task.wait(7)
		ShowCaption(rammessages[math.random(1, #rammessages)], 5)

		CreateSprintButton()
		SetupRoomHandler()              -- Ripper, Rebound, Frostbite (wait for door)
		SetupImmediateTimerSpawners()   -- Cease, Shocker, A60, Silence, Deer God (immediate)

		print("✅ Hardcore Mode Loaded!")
		print("📊 TIMER CONFIG:")
		print("   Room Wait Entities (need door):")
		print("      Ripper: " .. CONFIG.RIPPER_DELAY[1] .. "-" .. CONFIG.RIPPER_DELAY[2] .. " seconds")
		print("      Rebound: " .. CONFIG.REBOUND_DELAY[1] .. "-" .. CONFIG.REBOUND_DELAY[2] .. " seconds")
		print("      Frostbite: " .. CONFIG.FROSTBITE_DELAY[1] .. "-" .. CONFIG.FROSTBITE_DELAY[2] .. " seconds")
		print("   Immediate Spawn Entities (no door needed):")
		print("      Cease: " .. CONFIG.CEASE_DELAY[1] .. "-" .. CONFIG.CEASE_DELAY[2] .. " seconds")
		print("      Shocker: " .. CONFIG.SHOCKER_DELAY[1] .. "-" .. CONFIG.SHOCKER_DELAY[2] .. " seconds")
		print("      A60: " .. CONFIG.A60_DELAY[1] .. "-" .. CONFIG.A60_DELAY[2] .. " seconds")
		print("      Silence: " .. CONFIG.SILENCE_DELAY[1] .. "-" .. CONFIG.SILENCE_DELAY[2] .. " seconds")
		print("      DeerGod: " .. CONFIG.DEERGOD_DELAY[1] .. "-" .. CONFIG.DEERGOD_DELAY[2] .. " seconds")
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
