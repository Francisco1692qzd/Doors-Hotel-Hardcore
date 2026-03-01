local hints = {
    "Odd... I can't discover to who you died to..."
}

local rep = game.ReplicatedStorage
local remotesFolder = nil

task.spawn(function()
	local camera = workspace.CurrentCamera
	local cameraShaker = require(game.ReplicatedStorage.CameraShaker)
	local camShake = cameraShaker.new(Enum.RenderPriority.Camera.Value, function(cf)
		camera.CFrame = camera.CFrame * cf
	end)
	camShake:Start()
	local gameData = game.ReplicatedStorage:WaitForChild("GameData")
	local latestRoom = gameData:WaitForChild("LatestRoom")
	local ambruhheight = Vector3.new(0,3,0)
	local ambruhspeed = 160
	local DEF_SPEED = 9999
	local randomizedtimes = math.random(4, 9)
	local killed = false

	local player = game.Players.LocalPlayer
	local entity = game:GetObjects("rbxassetid://15972282065")[1]
	if entity == nil then return end
	entity.Parent = workspace
	local pr = entity:FindFirstChildWhichIsA("BasePart")
	print("true or false?")
	print("true or false?")
	local function GetTime(dist, speed)
		return dist / speed
	end
    local function canSeeTarget(target, size)
        if killed == true then return end
        local origin = pr.Position
        local direction = (target.HumanoidRootPart.Position - pr.Position).unit * size
        local ray = Ray.new(origin, direction)
        local hit = workspace:FindPartOnRay(ray, pr)
        if hit then
            if hit:IsDescendantOf(target) then
                killed = true
                return true
            end
        else
            return false
        end
    end
	wait(1)
	task.spawn(function()
		while entity ~= nil and entity.Parent ~= nil do wait(0.1)
			local v = game.Players.LocalPlayer
			local root = v.Character:FindFirstChild("HumanoidRootPart")
			if v.Character ~= nil and root ~= nil then
				if canSeeTarget(v.Character, 70) and not v.Character:GetAttribute("Hiding") then
					pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/refs/heads/main/wow!.lua"))() end)
					task.delay(0.01, function()
						v.Character.Humanoid.Health = 0
						game.ReplicatedStorage.GameStats["Player_".. root.Parent.Name].Total.DeathCause.Value = "A-60"
						    if ReplicatedStorage:FindFirstChild("RemotesFolder") then
								local remotesFolder = ReplicatedStorage:FindFirstChild("RemotesFolder")
			                    firesignal(remotesFolder.DeathHint.OnClientEvent, hints, "Blue")
							elseif ReplicatedStorage:FindFirstChild("Bricks") then
								local remotesFolder = ReplicatedStorage:FindFirstChild("Bricks")
			                    firesignal(remotesFolder.DeathHint.OnClientEvent, hints)
							end
					end)
				end
			end
			if v.Character ~= nil and root ~= nil and (pr.Position - root.Position).magnitude <= 70 then
				camShake:ShakeOnce(43, 20, 0.1, 2.3, 1, 6)
			end
		end
	end)

	local gruh = workspace.CurrentRooms
	ambruhspeed = DEF_SPEED

	local function Forward()
		local limit = game.ReplicatedStorage.GameData.LatestRoom.Value
		for i = 1, limit do
			local room = gruh:FindFirstChild(tostring(i))
			if room and room:FindFirstChild("Nodes") then
				local nodes = room.Nodes:GetChildren()
				table.sort(nodes, function(a,b) return tonumber(a.Name) < tonumber(b.Name) end)
				for _, node in ipairs(nodes) do
					local distance = (pr.Position - node.Position).magnitude
					local jerk = game.TweenService:Create(pr, TweenInfo.new(GetTime(distance, ambruhspeed), Enum.EasingStyle.Linear), {CFrame = node.CFrame + ambruhheight})
					jerk:Play()
					jerk.Completed:Wait()
					if ambruhspeed ~= 160 then ambruhspeed = 160 end
				end
			end
		end
	end

	local function Backward()
		local limit = game.ReplicatedStorage.GameData.LatestRoom.Value
		for i = limit, 1, -1 do
			local room = gruh:FindFirstChild(tostring(i))
			if room and room:FindFirstChild("Nodes") then
				local nodes = room.Nodes:GetChildren()
				table.sort(nodes, function(a,b) return tonumber(a.Name) < tonumber(b.Name) end)
				for n = #nodes, 1, -1 do
					local node = nodes[n]
					local distance = (pr.Position - node.Position).magnitude
					local jerk = game.TweenService:Create(pr, TweenInfo.new(GetTime(distance, ambruhspeed), Enum.EasingStyle.Linear), {CFrame = node.CFrame + ambruhheight})
					jerk:Play()
					jerk.Completed:Wait()
					if ambruhspeed ~= 160 then ambruhspeed = 160 end
				end
			end
		end
	end

	-- --- 🏃 THE REBOUNDS ---
	for i = 1, randomizedtimes do
		pcall(Forward)
		task.wait(1)
		pcall(Backward)
		task.wait(0.5)
	end
	entity:Destroy()
    local light = Instance.new("ColorCorrectionEffect")
    light.Parent = game.Lighting
    light.Brightness = -0.4
    light.Saturation = 0.4
    light.Contrast = -0.5
    light.TintColor = Color3.fromRGB(255, 0, 0)
    game.TweenService:Create(light, TweenInfo.new(20), {
        Brightness = 0,
        Contrast = 0,
        Saturation = 0,
        TintColor = Color3.fromRGB(255, 255, 255)
    }):Play() game.Debris:AddItem(light, 20)
    camShake:ShakeOnce(23, 45, 0, 16, 1, 6)
end)
