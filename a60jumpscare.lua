local ids = {"rbxassetid://11710144220", "rbxassetid://11710147805", "rbxassetid://12633510500","rbxassetid://17432116100"}
local hints = {
    "You died to who you call A-60...",
    "Since when he could appear lately at the most rarest moment?",
    "He's the fastest entity in the hotel!",
    "Find a safe spot when he arrive."
}

local G = getgenv()

G.LoadGithubAudio = function(url)
    if not (writefile and getcustomasset and request) then return nil end
    local cleanUrl = url .. "?t=" .. math.random(1, 100000)
    local response = request({
        Url = cleanUrl,
        Method = "GET",
        Headers = {["Accept"] = "audio/mpeg, audio/ogg, application/octet-stream"}
    })

    if response.StatusCode ~= 200 then
        warn("Xeno: Falha no download. Status: " .. response.StatusCode)
        return nil
    end

    local fileName = "A60Jumpscare_" .. tick() .. ".mp3"
    writefile(fileName, response.Body)
    
    local success, assetId = pcall(function()
        return getcustomasset(fileName)
    end)

    if success then return assetId end
    return nil
end

local jumpcare = Instance.new("ScreenGui")
local redBackground = Instance.new("Frame") -- The Epilepsy Background
local jumpare2 = Instance.new("ImageLabel")
local jumare3 = Instance.new("Sound")

jumpcare.Name = "A60_Jumpscare"
jumpcare.Parent = game.Players.LocalPlayer.PlayerGui
jumpcare.IgnoreGuiInset = true

-- Setup Red Background
redBackground.Name = "RedFlash"
redBackground.Parent = jumpcare
redBackground.Size = UDim2.new(1, 0, 1, 0)
redBackground.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
redBackground.BorderSizePixel = 0
redBackground.BackgroundTransparency = 1 -- Start invisible
redBackground.ZIndex = 1

jumpare2.Parent = jumpcare
jumpare2.AnchorPoint = Vector2.new(0.5, 0.5)
jumpare2.Position = UDim2.new(0.5, 0, 0.5, 0)
jumpare2.Size = UDim2.new(0.3, 0, 0.5, 0)
jumpare2.BackgroundTransparency = 1
jumpare2.Image = ids[math.random(1, #ids)]
jumpare2.ZIndex = 2 -- Ensure A-60 is on top of the red flash

jumare3.Parent = jumpcare
local jumpscareSound = G.LoadGithubAudio("https://raw.githubusercontent.com/DripCapybara/Doors-Modes/main/HardcoreMode/A-60jumpscare%20(1).mp3")
jumare3.SoundId = jumpscareSound 
jumare3.Volume = 3

-- [[ EXECUTION ]]
task.spawn(function()
    jumare3:Play()
    
    repeat task.wait() until jumare3.TimeLength > 0
    
    local soundTime = jumare3.TimeLength - 1.6
    local lungeDuration = 0.2 
    local shakeDuration = soundTime - lungeDuration
    
    local start = tick()
    
    -- Shake, Flicker, and Red Epilepsy Flash
    while tick() - start < shakeDuration do
        -- A-60 Glitch
        jumpare2.Image = ids[math.random(1, #ids)]
        local xOff = math.random(-60, 60) / 1000
        local yOff = math.random(-60, 60) / 1000
        jumpare2.Position = UDim2.new(0.5 + xOff, 0, 0.5 + yOff, 0)
        jumpare2.Rotation = math.random(-15, 15)
        
        -- Red Flash (Toggles transparency rapidly)
        redBackground.BackgroundTransparency = (math.random(1, 10) > 5) and 0.2 or 0.8
        
        task.wait(0.01)
    end
    
    -- Fade out the red background as we lunge
    game.TweenService:Create(redBackground, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
    
    -- Final Lunge
    local tweenInfo = TweenInfo.new(lungeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local lunge = game.TweenService:Create(jumpare2, tweenInfo, {
        Size = UDim2.new(2.5, 0, 3.5, 0),
        ImageTransparency = 1 
    })
    
    lunge:Play()
    lunge.Completed:Wait() 
    
    -- Kill Player
    if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
        --game.Players.LocalPlayer.Character.Humanoid.Health = 0
    end
    
    task.wait(4)
    jumpcare:Destroy()
end)
