local hints = {
    "You seem to have freeze'd out...",
    "Maybe something that can keep you warm?"
}

local rep = game.ReplicatedStorage
local remotesFolder = nil
local G = getgenv()

G.LoadGithubModel = function(url)
    if not (writefile and getcustomasset and request) then return nil end
    local response = request({Url = url, Method = "GET"})
    if response.StatusCode ~= 200 then return nil end
    local fileName = "frost_" .. tick() .. ".rbxm"
    writefile(fileName, response.Body)
    local assetId = getcustomasset(fileName)
    local success, result = pcall(function()
        return game:GetObjects(assetId)[1]
    end)
    if success and result then return result end
    return nil
end

local frostURL = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/main/newFrostbite.rbxm"

task.spawn(function()
    local camera = workspace.CurrentCamera
    local cameraShaker = require(game.ReplicatedStorage.CameraShaker)
    local camShake = cameraShaker.new(Enum.RenderPriority.Camera.Value, function(cf)
        camera.CFrame = camera.CFrame * cf
    end)
    camShake:Start()
    
    local gameData = game.ReplicatedStorage:WaitForChild("GameData")
    local latestRoom = gameData:WaitForChild("LatestRoom")
    local room = workspace.CurrentRooms:FindFirstChild(tostring(latestRoom.Value))
    
    local player = game.Players.LocalPlayer
    local entity = nil
    local shaking = true
    local active = false
    local turn1 = true

    if G.LoadGithubModel then
        entity = G.LoadGithubModel(frostURL)
        if entity then entity.Parent = workspace end
    end

    if not entity then return end

    local part = entity:FindFirstChild("Part")
    local static = part:FindFirstChild("Static Effect")
    static:Play()

    -- Node Placement
    local nodes = room:FindFirstChild("Nodes")
    if nodes then
        local childrenNodes = nodes:GetChildren()
        local randomNode = childrenNodes[math.random(1, #childrenNodes)]
        part.CFrame = randomNode.CFrame * CFrame.new(math.random(5, 10), 6, math.random(5, 10))
    end

    -- Initial Shake Loop
    task.spawn(function()
        while entity and entity.Parent and turn1 do
            task.wait(0.5)
            if shaking then camShake:ShakeOnce(14, 30, 0, 4) end
        end
    end)

    task.wait(5.33)
    shaking = false
    turn1 = false
    game.TweenService:Create(static, TweenInfo.new(1.4), {PlaybackSpeed = 0}):Play()
    task.wait(2.8)

    -- Active Shake Loop
    task.spawn(function()
        while entity and entity.Parent and active do
            task.wait(0.5)
            if not shaking then camShake:ShakeOnce(20, 30, 0, 3) end
        end
    end)

    active = true
    part.Ambience:Play()
    part.AmbienceFar:Play()
    part.Attachment.Heylois.Enabled = true
    part.Attachment.face.Enabled = true

    -- [[ THE HEAT DETECTION LOGIC ]]
    task.delay(1.3, function()
        task.spawn(function()
            while active and entity and entity.Parent do
                local char = player.Character
                if char and char:FindFirstChild("Humanoid") then
                    local hasHeat = false
                    
                    -- Only check for Lighter or Candle
                    local tool = char:FindFirstChild("Lighter") or char:FindFirstChild("Candle")
                    
                    if tool then
                        -- Check for active PointLight within the tool
                        for _, obj in ipairs(tool:GetDescendants()) do
                            if obj:IsA("PointLight") and obj.Enabled then
                                hasHeat = true
                                break
                            end
                        end
                    end

                    if not hasHeat and char.Humanoid.Health > 0 then
                        char.Humanoid:TakeDamage(10)
                        
                        -- Handle Death
                        if char.Humanoid.Health <= 0 then
                            pcall(function()
                                game.ReplicatedStorage.GameStats["Player_".. char.Name].Total.DeathCause.Value = "Frostbite"
                                local remote = rep:FindFirstChild("Bricks") or rep:FindFirstChild("RemotesFolder")
                                if remote then firesignal(remote.DeathHint.OnClientEvent, hints) end
                            end)
                            break
                        end
                    end
                end
                task.wait(1)
            end
        end)
    end)

    -- Wait for player to move to next room
    latestRoom.Changed:Wait()
    
    shaking = true
    active = false
    part.Ambience:Stop()
    part.AmbienceFar:Stop()
    part.Attachment.Heylois.Enabled = false
    part.Attachment.face.Enabled = false
    
    task.wait(2.6)
    entity:Destroy()
end)
