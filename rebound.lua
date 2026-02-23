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

local function Rebound()
    local repStorage = game.ReplicatedStorage
    local gameData = repStorage.GameData
    local latestRoom = gameData.LatestRoom
    local plusRoom = latestRoom.Value + 1
    local currentRooms = workspace.CurrentRooms
    local killed = false
    local speed = 2.2
    local entity = nil
    local cameraShaker = require(game.ReplicatedStorage.CameraShaker)
    local camera = workspace.CurrentCamera

    local camShake = cameraShaker.new(Enum.RenderPriority.Camera.Value, function(cf)
        camera.CFrame = camera.CFrame * cf
    end)
    camShake:Start()
    local reboundId = "rbxassetid://12254145022"
    local entity = game:GetObjects(reboundId)[1]
    entity.Parent = workspace

    if not entity then return end

    local function GetLastRoom()
        return currentRooms:FindFirstChild(plusRoom)
    end
    local entityPart = entity.PrimaryPart or entity:FindFirstChildWhichIsA("BasePart")
    entityPart.CFrame = GetLastRoom().RoomExit.CFrame
    entityPart.CanCollide = false
    entityPart.Anchored = true
    wait(4)
    local rebmoving = G.LoadGithubAudio("https://raw.githubusercontent.com/Francisco1692qzd/RevivedOldHardcore/main/MovingRebound.mp3")
    local moving = Instance.new("Sound")
    moving.SoundId = rebmoving
    moving.Parent = entityPart
    moving.Volume = 10
    moving:Play()--]]
    local function canSeeTarget(target, size)
        if killed == true then
            return
        end

        local origin = entityPart.Position
        local direction = (target.HumanoidRootPart.Position - origin).unit * size
        local ray = Ray.new(origin, direction)

        local hit, pos = workspace:FindPartOnRay(ray, entityPart)

        if hit then
            if hit:IsDescendantOf(target) then
                killed = true
                return true
            end
        else
            return false
        end
    end
    spawn(function()
        while entityPart ~= nil and entity ~= nil do wait(0.5)
            local v = game.Players.LocalPlayer
            if v.Character ~= nil and v.Character.HumanoidRootPart then
                if canSeeTarget(v.Character, 50) and not v.Character:GetAttribute("Hiding") then
                    moving:Stop()
                    local ReboundJs = Instance.new("ScreenGui")
                    local Static = Instance.new("ImageLabel")
                    local Rebound = Instance.new("ImageLabel")
                    local JSSIZE = Instance.new("ImageLabel")
 
                    ReboundJs.Name = "ReboundJs"
                    ReboundJs.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
 
                    Static.Name = "Static"
                    Static.Parent = ReboundJs
                    Static.BackgroundTransparency = 1
                    Static.Size = UDim2.new(11, 0, 111, 0)
                    Static.Image = "rbxassetid://236543215"
                    Static.ImageTransparency = 1
 
                    Rebound.Name = "Rebound"
                    Rebound.Parent = ReboundJs
                    Rebound.BackgroundTransparency = 1
                    Rebound.Position = UDim2.new(0.4866, 0, 0.4793, 0)
                    Rebound.Size = UDim2.new(0.0267, 0, 0.0387, 0)
                    Rebound.Image = "rbxassetid://10914800940"
 
                    JSSIZE.Name = "JSSIZE"
                    JSSIZE.Parent = ReboundJs
                    JSSIZE.BackgroundTransparency = 1
                    JSSIZE.Position = UDim2.new(-0.586, 0, -1.251, 0)
                    JSSIZE.Size = UDim2.new(2.128, 0, 3.081, 0)
                    JSSIZE.Visible = false
                    JSSIZE.Image = "rbxassetid://10914800940"
 
                    coroutine.wrap(function()
                        local script = Static
                        while true do
                            script.Image = "rbxassetid://236543215"
                            task.wait(0.002)
                            script.Rotation = 0
                            task.wait(0.002)
                            script.Rotation = 180
                            task.wait(0.002)
                            script.Image = "rbxassetid://236777652"
                            task.wait(0.002)
                            script.Rotation = 0
                            task.wait(0.002)
                            script.Rotation = 180
                            task.wait(0.002)
                        end
                    end)()
 
                    coroutine.wrap(function()
                        local Plr = game.Players.LocalPlayer
                        local gui = ReboundJs
                        local static = gui.Static
                        local jspos = gui.JSSIZE

                        local rebjumpscare = G.LoadGithubAudio("https://raw.githubusercontent.com/Francisco1692qzd/RevivedOldHardcore/main/JumpscareReb.mp3")
                        local jumpscare = Instance.new("Sound")
                        jumpscare.SoundId = rebjumpscare
                        jumpscare.Parent = workspace
                        jumpscare.Volume = 5
                        jumpscare:Play() game.Debris:AddItem(jumpscare, 10)
 
                        game.TweenService:Create(static, TweenInfo.new(0.5), {ImageTransparency = 0.8}):Play()
                        game.TweenService:Create(gui.Rebound, TweenInfo.new(0.5), {Size = jspos.Size, Position = jspos.Position}):Play()
                        task.spawn(function()
                            wait(0.3)
                            Plr.Character:FindFirstChildWhichIsA("Humanoid"):TakeDamage(100)
                            game.ReplicatedStorage.GameStats["Player_" .. Plr.Character.Name].Total.DeathCause.Value = "Rebound"
                            game.ReplicatedStorage.GameStats["Player_" .. Plr.Character.Name]["1"].DeathCause.Value = "Rebound"
                            --[[game.ReplicatedStorage.Bricks.DeathHint.OnClientEvent:Fire({
                                "You died to who you call Rebound...",
                                "He makes his presence known and keeps coming back...",
                                "Hide when this happens!"
                            })--]]
                            local hints = {
                                "You died to who you call Rebound...",
                                "He makes his presence known and keeps coming back...",
                                "Hide when this happens!"
                            }
                            if firesignal then
			                    firesignal(remotesFolder.DeathHint.OnClientEvent, hints, "Blue")
		                    else
			                    warn("firesignal not supported, ignore death hints.")
		                    end
                        end)
                        wait(0.5)
                        game.TweenService:Create(static, TweenInfo.new(1), {ImageTransparency = 1}):Play()
                        game.TweenService:Create(gui.Rebound, TweenInfo.new(0.3), {ImageTransparency = 1}):Play()
                        wait(1)
                        gui:Destroy()
                    end)()
                end
            end

            if entityPart and (entityPart.Position - v.Character.HumanoidRootPart.Position).Magnitude <= 60 then
                camShake:Start()
                camShake:ShakeOnce(17, 6, 0.1, 1)
            end
        end
    end)

    for i = latestRoom.Value, 1, -1 do
        if currentRooms:FindFirstChild(i) then
            local room = currentRooms[i]
            if room and room:FindFirstChild("RoomEntrance") then
                local abc = room:FindFirstChild("RoomEntrance")
                local jerk = game.TweenService:Create(entityPart, TweenInfo.new(speed, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0,false,0), {CFrame = abc.CFrame})
                jerk:Play()
                jerk.Completed:Wait()
            end
        end
    end

    entityPart.Anchored = false
    entityPart.CanCollide = false
    game.Debris:AddItem(entity, 5)
end
local function SpawnReb()
    local maxRebounds = 3
    local rebarrival = G.LoadGithubAudio("https://raw.githubusercontent.com/Francisco1692qzd/RevivedOldHardcore/main/Warning.mp3")
    local arrival = Instance.new("Sound")
    arrival.SoundId = rebarrival
    arrival.Parent = workspace
    arrival.Volume = 5
    arrival:Play() game.Debris:AddItem(arrival, 10)
    local cameraShaker = require(game.ReplicatedStorage.CameraShaker)
    local camera = workspace.CurrentCamera

    local camShake = cameraShaker.new(Enum.RenderPriority.Camera.Value, function(cf)
        camera.CFrame = camera.CFrame * cf
    end)
    local Warn = Instance.new("ColorCorrectionEffect", game.Lighting)
    Warn.TintColor = Color3.fromRGB(65, 138, 255)
    Warn.Saturation = -0.7
    Warn.Contrast = 0.2
    game.TweenService:Create(Warn, TweenInfo.new(15), {
        TintColor = Color3.fromRGB(255, 255, 255),
        Saturation = 0,
        Contrast = 0
    }):Play()                                                  game.Debris:AddItem(Warn, 15)
    camShake:Start()
    camShake:ShakeOnce(10, 3, 0.1, 6, 2, 0.5)
    pcall(Rebound)
    while maxRebounds > 0 do
        game.ReplicatedStorage.GameData.LatestRoom.Changed:Wait()
        wait(2)
        pcall(Rebound)
        maxRebounds = maxRebounds - 1
    end
end

spawn(SpawnReb)
