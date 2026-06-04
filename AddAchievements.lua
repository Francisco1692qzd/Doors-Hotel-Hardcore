local AchievementModule = game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game.RemoteListener.Modules.AchievementUnlock
if AchievementModule == nil then return end
if not game.ReplicatedStorage:FindFirstChild("ModulesShared") then return end
local dataModule = require(game:GetService("ReplicatedStorage"):WaitForChild("ModulesShared"):WaitForChild("Achievements"))
local unlockFunc = require(AchievementModule)

local function ImageLoader(url)
    if not (writefile and getcustomasset and request) then return nil end
    
    local rawUrl = url:gsub("github.com", "raw.githubusercontent.com"):gsub("/blob/", "/")
    
    -- Generate consistent filename from URL
    local function generateFileName(url)
        local hash = 0
        for i = 1, #url do
            hash = (hash * 31 + string.byte(url, i)) % 2^32
        end
        return "LoadedImageAchievement_" .. tostring(hash) .. ".png"
    end
    
    local fileName = generateFileName(rawUrl)
    
    -- Check if file exists and return it
    local success, exists = pcall(function()
        return isfile and isfile(fileName)
    end)
    
    if success and exists then
        return getcustomasset(fileName)
    end
    
    -- Download new image if not exists
    local response = request({Url = rawUrl, Method = "GET"})
    if response.StatusCode ~= 200 then return nil end
    
    writefile(fileName, response.Body)
    return getcustomasset(fileName)
end

local HardcoreSurvivorAchievement = "https://github.com/Francisco1692qzd/AchievementsImages/blob/main/Door100Achievement.png"
local SilenceAchievement = "https://github.com/Francisco1692qzd/AchievementsImages/blob/main/silenceachievement.png"
local Door100Image = ImageLoader(HardcoreSurvivorAchievement)
local silenceImage = ImageLoader(SilenceAchievement)

dataModule["HardcoreSurvivor"] = {
	GetInfo = function()
		return {
			Title = "HARDCORE SURVIVOR",
			Desc = "You survived the 100 rooms of Hardcore!",
			Reason = "Survive until Room 100. Congrats!",
			Image = Door100Image, -- Custom Icon ID
            Prize = {
                Knobs = 50,
                Stardust = 1
            }
		}
	end
}

dataModule["Shocker"] = {
	GetInfo = function()
		return {
			Title = "Shocking Experience",
			Desc = "Look at me."
			Reason = "Encounter Shocker."
			Image = "rbxassetid://94319277869668"
		}
	end
}

dataModule["Rebound"] = {
	GetInfo = function()
		return {
			Title = "Out of Many Rebounds",
			Desc = "Back for more!",
			Reason = "Encounter Rebound.",
			Image = "rbxassetid://14889947785"
		}
	end
}

dataModule["Ripper"] = {
	GetInfo = function()
		return {
			Title = "Torn Apart",
			Desc = "Don't Leave Too Early.",
			Reason = "Encounter Ripper.",
			Image = "rbxassetid://12231244908"
		}
	end
}

dataModule["DeerGod"] = {
	GetInfo = function()
		return {
			Title = "Running for my life",
			Desc = "Why are you running?",
			Reason = "Encounter Dear God.",
			Image = "rbxassetid://11394027261"
		}
	end
}

dataModule["Silence"] = {
	GetInfo = function()
		return {
			Title = "Eyes Closed Ears Open",
			Desc = "Better Hear or not",
			Reason = "Stay Silent to Encounter Silence!",
			Image = silenceImage
		}
	end
}
	--unlockFunc(nil, "Idiot")
print("Achievements Created Successfully")
