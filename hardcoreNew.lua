-- [[ MULTIPLAYER SYNC DATA ]]
local syncFolder = workspace:FindFirstChild("HardcoreSync") or Instance.new("Folder", workspace)
syncFolder.Name = "HardcoreSync"

local startTimeValue = syncFolder:FindFirstChild("HardcoreStartTime") or Instance.new("NumberValue", syncFolder)
startTimeValue.Name = "HardcoreStartTime"

local function SyncWait(seconds)
	if startTimeValue.Value == 0 then 
		repeat task.wait(0.5) until startTimeValue.Value > 0 
	end
	local targetTime = startTimeValue.Value + seconds
	while workspace:GetServerTimeNow() < targetTime do 
		task.wait(0.1) 
	end
end

-- [ORIGINAL HARDCORE BASE]
repeat task.wait() until game:IsLoaded()

local Player = game.Players.LocalPlayer
local LatestRoom = game.ReplicatedStorage.GameData.LatestRoom
local TS = game:GetService("TweenService")

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

-- [CRÉDITOS SUAVES]
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

	TS:Create(creditLabel, TweenInfo.new(1.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0.02, 0, 0.05, 0)}):Play()
	task.wait(5)
	local b = TS:Create(creditLabel, TweenInfo.new(1.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(-0.6, 0, 0.05, 0)})
	b:Play()
	b.Completed:Connect(function() creditGui:Destroy() end)
end

pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Francisco1692qzd/OverridenEntitiesMode/refs/heads/main/nodes.lua"))() end)

-- [DOOR 0 LOCK]
local alreadyExecuted = workspace:FindFirstChild("ExecutedHard")
Player.PlayerGui.MainUI.Initiator.Main_Game.Health.Music.Blue.PlaybackSpeed = 0.55
Player.PlayerGui.MainUI.Initiator.Main_Game.Health.Music.Blue.SoundId = "rbxassetid://10472612727"

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

local entityURLs = {
	Ripper = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/refs/heads/main/ripper.lua",
	Rebound = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/refs/heads/main/rebound.lua",
	DeerGod = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/refs/heads/main/deergod.lua",
	Cease = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/refs/heads/main/cease.lua",
	Shocker = "https://raw.githubusercontent.com/Francisco1692qzd/RevivedOldHardcore/refs/heads/main/oldShocker.lua",
	Silence = "https://raw.githubusercontent.com/Francisco1692qzd/RevivedOldHardcore/refs/heads/main/oldSilence.lua",
	A60 = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/refs/heads/a60.lua",
	Frostbite = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/refs/heads/frostbite.lua"
}

-- [SISTEMA DE STAMINA]
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
		local seekActive = workspace:FindFirstChild("SeekMovingNewClone") or workspace:FindFirstChild("SeekMoving")

		if seekActive then
			container.Visible = false
			stamina = 100
		else
			container.Visible = true
			if isExhausted then
				hum.WalkSpeed = 13
				stamina = math.min(100, stamina + 0.4)
				bar.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
				if not breathSound.IsPlaying then breathSound:Play() end
				if stamina >= 100 then isExhausted = false end
			elseif crouching then
				hum.WalkSpeed = 7
				stamina = math.min(100, stamina + 0.8)
			elseif sprinting and isMoving and stamina > 0 then
				hum.WalkSpeed = 19
				stamina = math.max(0, stamina - 1.2)
				if stamina <= 0 then isExhausted = true end
			else
				hum.WalkSpeed = 13
				stamina = math.min(100, stamina + 0.5)
				bar.BackgroundColor3 = Color3.fromRGB(255, 222, 189)
				if breathSound then breathSound:Stop() end
			end
			bar.Size = UDim2.new(stamina / 100, 0, 1, 0)
		end
	end
end)

local function LoadEntity(name)
	if workspace:FindFirstChild("SeekMovingNewClone") or workspace:FindFirstChild("SeekMoving") then return end
	local url = entityURLs[name]
	if url then task.spawn(function() pcall(function() loadstring(game:HttpGet(url))() end) end) end
end

-- [CONFIGURAÇÃO DE SPAWN]
local waitRipper, waitRebound, waitCease, waitA60 = 300, 550, 74, 230
local rammessages = {
	"That script gave so much work.",
	"If you didn't like it, please, atleast have fun.",
	"You don't like it? you didn't even played it already!",
	"Hardcore V5 by Noonie and Ping."
}

local opened = false
LatestRoom.Changed:Connect(function()
	if not opened and LatestRoom.Value == 1 then
		opened = true
		if startTimeValue.Value == 0 then startTimeValue.Value = workspace:GetServerTimeNow() end

		task.spawn(ShowSmoothCredits)
		ShowCaption("Hardcore Initiated.", 5)
		task.wait(3)
		ShowCaption("Have fun " .. Player.Name .. ".", 4)
		task.wait(7)
		ShowCaption(rammessages[math.random(1, #rammessages)], 5)

		-- SYNCED LOOPS (Multiplayer Logic)
		task.spawn(function() local c = 0 while true do SyncWait(c+80) if LatestRoom.Value >= 1 then LatestRoom.Changed:Wait() LoadEntity("Ripper") end SyncWait(c+167) if LatestRoom.Value >= 1 then LatestRoom.Changed:Wait() LoadEntity("Ripper") end c=c+300 task.wait(1) end end)
		task.spawn(function() local c = 0 while true do SyncWait(c+189) if LatestRoom.Value >= 1 then LatestRoom.Changed:Wait() LoadEntity("Frostbite") end SyncWait(c+320) if LatestRoom.Value >= 1 then LatestRoom.Changed:Wait() LoadEntity("Frostbite") end c=c+320 task.wait(1) end end)
		task.spawn(function() local c = 0 while true do SyncWait(c+290) if LatestRoom.Value >= 1 then LatestRoom.Changed:Wait() LoadEntity("Rebound") end SyncWait(c+410) if LatestRoom.Value >= 1 then LatestRoom.Changed:Wait() LoadEntity("Rebound") end c=c+450 task.wait(1) end end)
		task.spawn(function() local c = 0 while true do SyncWait(c+160) LoadEntity("Cease") SyncWait(c+390) LoadEntity("Cease") c=c+390 task.wait(1) end end)
		task.spawn(function() local c = 0 while true do SyncWait(c+450) LoadEntity("A60") SyncWait(c+720) LoadEntity("A60") c=c+720 task.wait(1) end end)
		
		task.spawn(function() local c = 0 while true do SyncWait(c+455) LoadEntity("Silence") SyncWait(c+600) LoadEntity("Silence") c=c+600 task.wait(1) end end)
		task.spawn(function() local c = 0 while true do SyncWait(c+420) LoadEntity("DeerGod") c=c+500 task.wait(1) end end)
		task.spawn(function() while true do task.wait(math.random(30, 70)) LoadEntity("Shocker") end end)
	end
end)
