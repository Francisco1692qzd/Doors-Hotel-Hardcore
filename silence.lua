-- XENO GITHUB MODEL LOADER (.rbxm / .rbxmx)
local G = getgenv()

-- Garantindo que a função exista no ambiente Global
G.LoadGithubModel = function(url)
    if not (writefile and getcustomasset and request) then
        return nil
    end
    
    -- Generate consistent filename from URL
    local function generateFileName(url)
        local hash = 0
        for i = 1, #url do
            hash = (hash * 31 + string.byte(url, i)) % 2^32
        end
        return "silence_" .. tostring(hash) .. ".rbxm"
    end
    
    local fileName = generateFileName(url)
    
    -- Check if file exists and try to load it
    local success, exists = pcall(function()
        return isfile and isfile(fileName)
    end)
    
    if success and exists then
        local assetId = getcustomasset(fileName)
        local loadSuccess, result = pcall(function()
            return game:GetObjects(assetId)[1]
        end)
        
        if loadSuccess and result then
            return result
        end
    end
    
    -- Download new model if not exists or failed to load
    local response = request({Url = url, Method = "GET"})
    if response.StatusCode ~= 200 then return nil end
    
    writefile(fileName, response.Body)
    local assetId = getcustomasset(fileName)
    local success, result = pcall(function()
        return game:GetObjects(assetId)[1]
    end)
    
    if success and result then return result end
    return nil
end

local function Silence()
    local currentRooms = workspace.CurrentRooms
    local latestRoom = game.ReplicatedStorage.GameData.LatestRoom
    local ambruhspeed = 15
    local ambruhheight = Vector3.new(0,3.4,0)
    local DEF_SPEED = 99999
    local storer = ambruhspeed
    local entity = nil
    local killed = false
	if not game.ReplicatedStorage:FindFirstChild("ModuleClients") then return end
    if not game.ReplicatedStorage.ModuleClients:FindFirstChild("Module_Events") then return end
    if not workspace:FindFirstChild("CurrentRooms") then return end
    local required = require(game.ReplicatedStorage.ModuleClients.Module_Events)
    local currentRooms = workspace:FindFirstChild("CurrentRooms")
    local latestRoomInt = game.ReplicatedStorage.GameData.LatestRoom
    local latestRoomModel = currentRooms:FindFirstChild(latestRoomInt.Value)
    local playerGui = game.Players.LocalPlayer.PlayerGui
    local remotesFolde = nil
    if game.ReplicatedStorage:FindFirstChild("RemotesFolder") then remotesFolde = game.ReplicatedStorage:FindFirstChild("RemotesFolder") end
    local moduleScripts = {
	      Module_Events = require(game.ReplicatedStorage.ModulesClient.Module_Events),
	      Main_Game = require(playerGui.MainUI.Initiator.Main_Game),
	      Earthquake = require(remotesFolde.RequestAsset:InvokeServer("Earthquake"))
    }
    --required.flickerLights(latestRoomModel, 74)
    local rawUrl = "https://raw.githubusercontent.com/Francisco1692qzd/RevivedOldHardcore/main/oldSilence.rbxm"
    -- CORREÇÃO DE ESCOPO: Atribuindo o retorno à variável local correta
    if G.LoadGithubModel then
        entity = G.LoadGithubModel(rawUrl)
        if entity then
            entity.Parent = workspace
        end
    end

    if not entity then return end -- Se falhar, para aqui sem quebrar o resto

    local entityPart = entity:FindFirstChildWhichIsA("BasePart")

    wait(1)
    local function canSeeTarget(target, size)
        if killed == true then
            return
        end

        local origin = entityPart.Position
        local direction = (target.HumanoidRootPart.Position - origin).unit * size
        local ray = Ray.new(origin, direction)

        local hit, pos = workspace:FindPartOnRay(ray, entity)

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
        while entity ~= nil and entityPart ~= nil and entity.Parent do wait(0.7)
            local v = game.Players.LocalPlayer
            if v.Character ~= nil and v.Character.HumanoidRootPart then
                if canSeeTarget(v.Character, 50) and not v.Character:GetAttribute("Hiding") then
                    v.Character.Humanoid:TakeDamage(100)
                    game.ReplicatedStorage.GameStats["Player_".. v.Character.Name].Total.DeathCause.Value = "Silence"
                            local hints = {
                                "You died to who you call Silence...",
                                "Its heard when you're quiet!",
								"It's definitely not recommended to run... but run if you can!",
								"Hiding in a far away spot should be safer."
                            }
							if ReplicatedStorage:FindFirstChild("RemotesFolder") then
								local remotesFolder = ReplicatedStorage:FindFirstChild("RemotesFolder")
			                    firesignal(remotesFolder.DeathHint.OnClientEvent, hints, "Blue")
							elseif ReplicatedStorage:FindFirstChild("Bricks") then
								local remotesFolder = ReplicatedStorage:FindFirstChild("Bricks")
			                    firesignal(remotesFolder.DeathHint.OnClientEvent, hints)
							end
                end
            end
        end
    end)
    ambruhspeed = DEF_SPEED
    for i = 1, latestRoom.Value do
        if currentRooms:FindFirstChild(i) then
            local room = currentRooms[i]
            if room and room:FindFirstChild("Nodes") then
                local nodes = room:FindFirstChild("Nodes")
                moduleScripts.Module_Events.shatter(room)
                for v = 1, #nodes:GetChildren() do
                    if nodes:FindFirstChild(v) then
                        local node = nodes[v]
                        local dist = (entityPart.Position - node.Position).magnitude
                        local STOPSTEALINGBRODONTYOUHAVEAMOMMYTOLOVEYOUORYOUGOTADOPTED = game.TweenService:Create(entityPart, TweenInfo.new(GetTime(dist, ambruhspeed), Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0,false,0), {CFrame = node.CFrame + ambruhheight})
                        STOPSTEALINGBRODONTYOUHAVEAMOMMYTOLOVEYOUORYOUGOTADOPTED:Play()
                        STOPSTEALINGBRODONTYOUHAVEAMOMMYTOLOVEYOUORYOUGOTADOPTED.Completed:Wait()
                        ambruhspeed = storer
                    end
                end
            end
        end
    end

    game.TweenService:Create(entityPart, TweenInfo.new(1.5), {CFrame = entityPart.CFrame * CFrame.new(0, -80, 0)}):Play()
    game.Debris:AddItem(entity, 1.5)
	local AchievementModule = game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game.RemoteListener.Modules.AchievementUnlock
	if AchievementModule == nil then return end
	if workspace:FindFirstChild("SilenceAchievement") then return end
	if not game.ReplicatedStorage:FindFirstChild("ModulesShared") then return end
	local dataModule = require(game:GetService("ReplicatedStorage"):WaitForChild("ModulesShared"):WaitForChild("Achievements"))
	local unlockFunc = require(AchievementModule)
	if not workspace:FindFirstChild("SilenceAchievement") then
		unlockFunc(nil, "Silence") 
	end
	local ObtainedBadge = Instance.new("BoolValue")
	ObtainedBadge.Name = "SilenceAchievement"
	ObtainedBadge.Value = true
	ObtainedBadge.Parent = workspace
end

pcall(Silence)
