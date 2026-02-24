local G = getgenv()
local ReplicatedStorage = game.ReplicatedStorage
local remotesFolder = ReplicatedStorage:WaitForChild("RemotesFolder")

G.LoadGithubAudio = function(url)
    if not (writefile and getcustomasset and request) then return nil end

    -- Bypass de Cache: Adiciona um número aleatório ao final para forçar o download limpo
    local cleanUrl = url .. "?t=" .. math.random(1, 100000)

    local response = request({
        Url = cleanUrl,
        Method = "GET",
        Headers = {
            ["Accept"] = "audio/mpeg, audio/ogg, application/octet-stream"
        }
    })

    if response.StatusCode ~= 200 then
        warn("Xeno: Falha no download. Status: " .. response.StatusCode)
        return nil
    end

    -- Nome único para evitar conflitos de escrita
    local fileName = "rebound_fix_" .. tick() .. ".mp3"
    
    -- Salva e força a leitura
    writefile(fileName, response.Body)
    
    local success, assetId = pcall(function()
        return getcustomasset(fileName)
    end)

    if success then
        print("✅ Áudio Rebound carregado com sucesso!")
        return assetId
    end
    
    warn("Erro no getcustomasset: " .. tostring(assetId))
    return nil
end

local function SPAWNHORROR()
    local breakMove = false
    local killed = false
    local repStorage = game.ReplicatedStorage
    local gameData = repStorage.GameData
    local latestRoom = gameData.LatestRoom
    local currentRooms = workspace.CurrentRooms
    local entity = nil
    local ambruhspeed = 120
    local DEF_SPEED = 99999 -- MANTIDO original
    local storer = ambruhspeed
    local ambruhheight = Vector3.new(0,8,0)
    local cameraShaker = require(repStorage.CameraShaker)
    local camera = workspace.CurrentCamera
    local camShake = cameraShaker.new(Enum.RenderPriority.Camera.Value, function(cf)
        camera.CFrame = camera.CFrame * cf
    end)
    camShake:Start()
    camShake:Shake(cameraShaker.Presets.Earthquake)
    local ripperId = "rbxassetid://12797541507"
    local entity = game:GetObjects(ripperId)[1]
    entity.Parent = workspace

    if not entity then return end -- Se falhar, para aqui sem quebrar o resto
    
    local tweenLights = TweenInfo.new(1)
    local color = {Color = Color3.fromRGB(255, 0, 0)}
    for i, v in pairs(currentRooms:GetDescendants()) do
        if v:IsA("Light") then
            game.TweenService:Create(v, tweenLights, color):Play()
            if v.Parent.Name == "LightFixture" then
                game.TweenService:Create(v.Parent, tweenLights, color):Play()
            end
        end
    end
    local spawnSound = entity.Ripe.Spawn:Clone()
    entity.Ripe.Spawn:Destroy()
    spawnSound.Parent = workspace
    spawnSound.TimePosition = 0
    spawnSound.Looped = false
    spawnSound:Play()
    
    local entityPart = entity:FindFirstChildWhichIsA("BasePart")

    local function canSeeTarget(target, size)
        if killed == true then return end
        local origin = entityPart.Position
        local direction = (target.HumanoidRootPart.Position - origin).unit * size
        local ray = Ray.new(origin, direction)
        local hit = workspace:FindPartOnRay(ray, entityPart)
        if hit then
            if hit:IsDescendantOf(target) then
                killed = true
                return true
            end
        else
            return false
        end
    end

    local function GetTime(dist, speed)
        return dist / speed
    end

    spawn(function()
        while entityPart ~= nil and entity ~= nil do wait(0.2)
            local v = game.Players.LocalPlayer
            if v.Character ~= nil and v.Character.HumanoidRootPart then
                if canSeeTarget(v.Character, 50) and not v.Character:GetAttribute("Hiding") then
                    breakMove = true
                    -- Toda a sua lógica de GUI e Jumpscare preservada abaixo
                    local gui = Instance.new("ScreenGui", v:WaitForChild("PlayerGui"))
                    gui.Name = "Noise"
                    gui.IgnoreGuiInset = true
                    local img = Instance.new("ImageLabel", gui)
                    img.Size = UDim2.new(1, 0, 1, 0)
                    img.BackgroundTransparency = 1
                    img.Image = "rbxassetid://236542974"
                    img.ImageTransparency = 1

                    coroutine.wrap(function()
                        local char = v.Character
                        local ripper = entityPart
                        local clone = ripper and ripper:Clone()
                        if not clone then return end
                        clone.Parent = workspace
                        clone.Position = ripper.Position
                        for _, x in ipairs(clone:GetDescendants()) do
                            if x:IsA("ParticleEmitter") then
                                spawn(function() x.Rate = 9999; wait(0.25); x.TimeScale = 0.0 end)
                            elseif x:IsA("Sound") then x.Volume = 0 end
                        end
                        entity:Destroy()
                        local static = Instance.new("Sound", workspace)
                        static.SoundId = "rbxassetid://372770465"
                        static.Volume = 10
                        static.Pitch = 0.7
                        local anchor = Instance.new("Part", workspace)
                        anchor.Name = "ripperAnchor"
                        anchor.Anchored = true
                        anchor.CanCollide = false
                        anchor.Transparency = 1
                        anchor.CFrame = workspace.CurrentCamera.CFrame
                        char:FindFirstChild("HumanoidRootPart").Anchored = true
                        workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
                        local viewLoop = true
                        spawn(function()
                            while viewLoop do
                                workspace.CurrentCamera.CFrame = anchor.CFrame
                                img.Image = "rbxassetid://"..({8482795900,236542974,184251462,236777652})[math.random(1,4)]
                                game["Run Service"].RenderStepped:Wait()
                            end
                        end)
                        game.TweenService:Create(anchor, TweenInfo.new(0.3), {CFrame = CFrame.lookAt(anchor.Position, clone.Position)}):Play()
                        wait(1)
                        game.TweenService:Create(img, TweenInfo.new(2), {ImageTransparency = 0}):Play()
                        static:Play()
                        wait(2)
                        viewLoop = false
                        game.TweenService:Create(img, TweenInfo.new(1), {ImageTransparency = 1}):Play()
                        static:Destroy()
                        char:FindFirstChild("HumanoidRootPart").Anchored = false
                        game.ReplicatedStorage.GameStats["Player_" .. v.Character.Name].Total.DeathCause.Value = "Ripper"
                        game.ReplicatedStorage.GameStats["Player_" .. v.Character.Name]["1"].DeathCause.Value = "Ripper"
                        char:FindFirstChildWhichIsA("Humanoid"):TakeDamage(100)
                            local hints = {
                                "You died to who you call Ripper...",
                                "He screams so making you know his presence is here...",
                                "Hide when this happens!"
                            }
                            if firesignal then
			                    firesignal(remotesFolder.DeathHint.OnClientEvent, hints, "Blue")
		                    else
			                    warn("firesignal not supported, ignore death hints.")
		                    end
                    end)()
                end
            end
            if v.Character ~= nil and v.Character.HumanoidRootPart and (entityPart.Position - v.Character.HumanoidRootPart.Position).magnitude <= 60 then
                camShake:Start()
                camShake:ShakeOnce(15, 25, 0, 2, 1, 6)
            end
            if breakMove then break end
        end
    end)

    -- MOVIMENTO POR NODES ORIGINAL
    entityPart.Ambush.SoundId = "rbxassetid://6963538865"
    entityPart.Ambush.PlaybackSpeed = 0.37
    entityPart.Ambush:Stop()
    entityPart.Ambush.Volume = 10
    wait(8)
    entityPart.Ambush:Play()
    game.TweenService:Create(entityPart.Ambush, TweenInfo.new(6), {Volume = 0.8}):Play()
    ambruhspeed = DEF_SPEED

    for i = 1, latestRoom.Value do
        local room = currentRooms:FindFirstChild(tostring(i))
        if room and room:FindFirstChild("Nodes") then
            local nodes = room.Nodes
            for v_idx = 1, #nodes:GetChildren() do
                local node = nodes:FindFirstChild(tostring(v_idx))
                if node then
                    if breakMove then break end
                    local dist = (entityPart.Position - node.Position).magnitude
                    local bruh = game.TweenService:Create(entityPart, TweenInfo.new(GetTime(dist, ambruhspeed), Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0,false,0), {CFrame = node.CFrame + ambruhheight})
                    bruh:Play()
                    bruh.Completed:Wait()
                    ambruhspeed = storer
                    if room.Name == tostring(latestRoom.Value) then
                        pcall(function() room.Door.ClientOpen:FireServer() end)
                    end
                end
            end
        end
        if breakMove then break end
    end

    local slam = Instance.new("Sound", entityPart)
    slam.Volume = 10
    slam.SoundId = "rbxassetid://1837829565"
    camShake:Shake(cameraShaker.Presets.Explosion)
    pcall(function() workspace.CurrentRooms[latestRoom.Value].Door.ClientOpen:FireServer() end)
    slam:Play()
    wait(1)
    entityPart.Anchored = false
    entityPart.CanCollide = false
    game.Debris:AddItem(entity, 5)
end
pcall(SPAWNHORROR)
