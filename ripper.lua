local G = getgenv()
local ReplicatedStorage = game.ReplicatedStorage
local remotesFolder = ReplicatedStorage:WaitForChild("RemotesFolder")

-- [SYSTEM: GITHUB LOADERS]
G.LoadGithubModel = function(url)
    if not (writefile and getcustomasset and request) then return nil end
    local response = request({Url = url, Method = "GET"})
    if response.StatusCode ~= 200 then return nil end
    local fileName = "temp_model_" .. tick() .. ".rbxm"
    writefile(fileName, response.Body)
    local assetId = getcustomasset(fileName)
    local success, result = pcall(function() return game:GetObjects(assetId)[1] end)
    return success and result or nil
end

G.LoadGithubAudio = function(url)
    if not (writefile and getcustomasset and request) then return nil end
    local cleanUrl = url .. "?t=" .. math.random(1, 100000)
    local response = request({Url = cleanUrl, Method = "GET"})
    if response.StatusCode ~= 200 then return nil end
    local fileName = "audio_fix_" .. tick() .. ".mp3"
    writefile(fileName, response.Body)
    local success, assetId = pcall(function() return getcustomasset(fileName) end)
    return success and assetId or nil
end

-- [CORE: SPAWNHORROR]
local function SPAWNHORROR()
    local breakMove = false
    local killed = false
    local repStorage = game.ReplicatedStorage
    local gameData = repStorage.GameData
    local latestRoom = gameData.LatestRoom
    local currentRooms = workspace.CurrentRooms
    local player = game.Players.LocalPlayer
    
    -- [CAMERA SHAKER SETUP - ORIGINAL PRESETS]
    local cameraShaker = require(repStorage.CameraShaker)
    local camera = workspace.CurrentCamera
    local camShake = cameraShaker.new(Enum.RenderPriority.Camera.Value, function(cf)
        camera.CFrame = camera.CFrame * cf
    end)
    camShake:Start()
    camShake:Shake(cameraShaker.Presets.Earthquake)

    -- [MODEL LOADING]
    local rawURL = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/main/newRipper.rbxm"
    local entity = G.LoadGithubModel(rawURL)
    if not entity then return end
    entity.Parent = workspace
    
    local entityPart = entity:FindFirstChildWhichIsA("BasePart")
    if not entityPart then return end

    -- [FIXED LIGHTS LOOP: ONLY CURRENT ROOMS]
    task.spawn(function()
        local tweenLights = TweenInfo.new(1)
        local color = {Color = Color3.fromRGB(255, 0, 0)}
        -- Only loops through visible rooms to prevent global game lag
        for i = latestRoom.Value - 2, latestRoom.Value do
            local room = currentRooms:FindFirstChild(tostring(i))
            if room then
                for _, v in ipairs(room:GetDescendants()) do
                    if v:IsA("Light") then
                        game.TweenService:Create(v, tweenLights, color):Play()
                    end
                end
            end
        end
    end)

    -- [SOUND SETUP]
    local spawnSound = entity.Ripe.Spawn:Clone()
    entity.Ripe.Spawn:Destroy()
    spawnSound.Parent = workspace
    spawnSound:Play()

    -- [MODERN RAYCAST (REPLACES DEPRECATED FINDONRAY)]
    local function canSeeTarget(target)
        if killed or not entityPart then return false end
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {entity, target}
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        
        local result = workspace:Raycast(entityPart.Position, (target.HumanoidRootPart.Position - entityPart.Position), rayParams)
        return result == nil -- If nil, path is clear
    end

    -- [DETECTION LOOP]
    task.spawn(function()
        while entity and entity.Parent and not breakMove do
            task.wait(0.1)
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                -- Jumpscare Trigger
                if not char:GetAttribute("Hiding") and canSeeTarget(char) then
                    breakMove = true
                    killed = true
                    
                    -- [JUMPSCARE SEQUENCE]
                    local gui = Instance.new("ScreenGui", player.PlayerGui)
                    gui.Name = "Noise"
                    gui.IgnoreGuiInset = true
                    local img = Instance.new("ImageLabel", gui)
                    img.Size = UDim2.new(1, 0, 1, 0)
                    img.BackgroundTransparency = 1
                    img.Image = "rbxassetid://236542974"

                    task.spawn(function()
                        local char = player.Character
                        local clone = entityPart:Clone()
                        clone.Parent = workspace
                        clone.Position = entityPart.Position
                        
                        for _, x in ipairs(clone:GetDescendants()) do
                            if x:IsA("ParticleEmitter") then 
                                x.Rate = 9999
                                task.delay(0.25, function() x.TimeScale = 0 end)
                            elseif x:IsA("Sound") then x.Volume = 0 end
                        end
                        
                        entity:Destroy()
                        local static = Instance.new("Sound", workspace)
                        static.SoundId = "rbxassetid://372770465"
                        static.Volume = 10
                        static.Pitch = 0.7
                        
                        local anchor = Instance.new("Part", workspace)
                        anchor.Anchored = true
                        anchor.Transparency = 1
                        anchor.CFrame = camera.CFrame
                        
                        char.HumanoidRootPart.Anchored = true
                        camera.CameraType = Enum.CameraType.Scriptable
                        
                        local viewLoop = true
                        task.spawn(function()
                            while viewLoop do
                                camera.CFrame = anchor.CFrame
                                img.Image = "rbxassetid://"..({8482795900,236542974,184251462,236777652})[math.random(1,4)]
                                game:GetService("RunService").RenderStepped:Wait()
                            end
                        end)

                        game.TweenService:Create(anchor, TweenInfo.new(0.3), {CFrame = CFrame.lookAt(anchor.Position, clone.Position)}):Play()
                        task.wait(1)
                        game.TweenService:Create(img, TweenInfo.new(2), {ImageTransparency = 0}):Play()
                        static:Play()
                        task.wait(2)
                        
                        viewLoop = false
                        char.HumanoidRootPart.Anchored = false
                        camera.CameraType = Enum.CameraType.Custom
                        char.Humanoid:TakeDamage(100)
                        
                        local hints = {"You died to who you call Ripper...", "He screams so making you know his presence is here...", "Hide when this happens!"}
                        firesignal(remotesFolder.DeathHint.OnClientEvent, hints, "Blue")
                    end)
                end
                
                -- Distance Shake
                local dist = (entityPart.Position - char.HumanoidRootPart.Position).Magnitude
                if dist <= 60 then
                    camShake:ShakeOnce(15, 25, 0, 2)
                end
            end
        end
    end)

    -- [MOVEMENT LOGIC]
    entityPart.Ambush.SoundId = "rbxassetid://6963538865"
    entityPart.Ambush.PlaybackSpeed = 0.37
    entityPart.Ambush.Volume = 10
    task.wait(8)
    entityPart.Ambush:Play()
    game.TweenService:Create(entityPart.Ambush, TweenInfo.new(6), {Volume = 0.8}):Play()

    local ambruhheight = Vector3.new(0, 8, 0)
    for i = 1, latestRoom.Value do
        if breakMove then break end
        local room = currentRooms:FindFirstChild(tostring(i))
        local nodes = room and room:FindFirstChild("Nodes")
        if nodes then
            for v_idx = 1, #nodes:GetChildren() do
                local node = nodes:FindFirstChild(tostring(v_idx))
                if node and not breakMove then
                    local dist = (entityPart.Position - node.Position).Magnitude
                    local speed = (i == latestRoom.Value) and 99999 or 120
                    local tInfo = TweenInfo.new(dist/speed, Enum.EasingStyle.Linear)
                    
                    local tween = game.TweenService:Create(entityPart, tInfo, {CFrame = node.CFrame + ambruhheight})
                    tween:Play()
                    tween.Completed:Wait()
                end
            end
        end
    end

    -- [DESPAWN]
    local slam = Instance.new("Sound", entityPart)
    slam.Volume = 10
    slam.SoundId = "rbxassetid://1837829565"
    camShake:Shake(cameraShaker.Presets.Explosion)
    pcall(function() currentRooms[tostring(latestRoom.Value)].Door.ClientOpen:FireServer() end)
    slam:Play()
    task.wait(1)
    game.Debris:AddItem(entity, 1)
end

pcall(SPAWNHORROR)
