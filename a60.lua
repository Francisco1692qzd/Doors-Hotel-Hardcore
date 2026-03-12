local hints = {
    "Odd... I can't discover to who you died to..."
}

local rep = game.ReplicatedStorage

-- [[ FORCE LOAD: Retries 20 times to bypass Roblox asset loading lag ]]
local function loadModel(id)
    local obj = nil
    local attempts = 0
    local maxAttempts = 20

    while obj == nil and attempts < maxAttempts do
        attempts = attempts + 1
        local success, result = pcall(function()
            return game:GetObjects("rbxassetid://" .. id)
        end)

        if success and result and result[1] then
            obj = result[1]
            --print("✅ Depth Model Loaded successfully on attempt: " .. attempts)
        else
            --warn("⚠️ Attempt " .. attempts .. " failed to load model " .. id .. ". Retrying...")
            task.wait(0.5) -- Small breather for the engine
        end
    end

    if not obj then
        warn("❌ CRITICAL: Failed to load model after 20 attempts.")
    end
    
    return obj
end

local function isBossActive()
    local gameData = game.ReplicatedStorage:FindFirstChild("GameData")
    if not gameData then return false end
    local latestRoom = gameData:FindFirstChild("LatestRoom")
    
    local room = latestRoom.Value
    if room == 48 or room == 99 then return true end
    
    for _, sound in pairs(game.ReplicatedStorage:GetDescendants()) do
        if sound:IsA("Sound") and sound.IsPlaying and (sound.Name:find("Music") or sound.Name == "Shade") then
            return true
        end
    end
    return false
end

task.spawn(function()
    local camera = workspace.CurrentCamera
    local shakerModule = game.ReplicatedStorage:FindFirstChild("CameraShaker")
    if not shakerModule then return end
    
    local cameraShaker = require(shakerModule)
    local camShake = cameraShaker.new(Enum.RenderPriority.Camera.Value, function(cf)
        camera.CFrame = camera.CFrame * cf
    end)
    camShake:Start()

    local gameData = game.ReplicatedStorage:WaitForChild("GameData")
    local latestRoom = gameData:WaitForChild("LatestRoom")
    local ambruhheight = Vector3.new(0, 3, 0)
    local ambruhspeed = 160
    local DEF_SPEED = 9999
    local randomizedtimes = math.random(4, 9)
    local killed = false

    local entity = loadModel(15972282065) -- The 20-attempt loop starts here
    if not entity then return end
    
    entity.Parent = workspace
    local pr = entity:FindFirstChildWhichIsA("BasePart") or entity:FindFirstChildWhichIsA("MeshPart")
    if not pr then return end

    local function GetTime(dist, speed)
        return dist / speed
    end

    local function canSeeTarget(target, size)
        if killed then return end
        local origin = pr.Position
        local targetPos = target.HumanoidRootPart.Position
        local direction = (targetPos - pr.Position).unit * size
        local ray = Ray.new(origin, direction)
        local hit = workspace:FindPartOnRay(ray, pr)
        
        if hit and hit:IsDescendantOf(target) then
            return true
        end
        return false
    end

    task.wait(1)

    -- Kill/Shake Loop
    task.spawn(function()
        while entity and entity.Parent do 
            task.wait(0.1)
            local v = game.Players.LocalPlayer
            if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                local root = v.Character.HumanoidRootPart
                
                if canSeeTarget(v.Character, 70) and not v.Character:GetAttribute("Hiding") then
                    killed = true
                    pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/refs/heads/main/wow!.lua"))() end)
                    
                    task.delay(1.3, function()
                        --v.Character.Humanoid.Health = 0
                        local stats = rep:FindFirstChild("GameStats")
                        if stats and stats:FindFirstChild("Player_".. v.Name) then
                            stats["Player_".. v.Name].Total.DeathCause.Value = "A-60"
                        end
                        
                        local remotes = rep:FindFirstChild("RemotesFolder") or rep:FindFirstChild("Bricks")
                        if remotes and remotes:FindFirstChild("DeathHint") then
                            if remotes.Name == "RemotesFolder" then
                                firesignal(remotes.DeathHint.OnClientEvent, hints, "Blue")
                            else
                                firesignal(remotes.DeathHint.OnClientEvent, hints)
                            end
                        end
                    end)
                end

                if (pr.Position - root.Position).magnitude <= 70 then
                    camShake:ShakeOnce(43, 20, 0.1, 2.3, 1, 6)
                end
            end
        end
    end)

    local gruh = workspace.CurrentRooms
    ambruhspeed = DEF_SPEED

    local function Forward()
        local limit = latestRoom.Value
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
        local limit = latestRoom.Value
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
        task.wait(1)
    end

    entity:Destroy()
    
    local light = Instance.new("ColorCorrectionEffect", game.Lighting)
    light.Brightness, light.Saturation, light.Contrast = -0.4, 0.4, -0.5
    light.TintColor = Color3.fromRGB(255, 0, 0)
    
    game.TweenService:Create(light, TweenInfo.new(20), {
        Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.fromRGB(255, 255, 255)
    }):Play()
    
    game.Debris:AddItem(light, 20)
    camShake:ShakeOnce(23, 45, 0, 16, 1, 6)
end)
