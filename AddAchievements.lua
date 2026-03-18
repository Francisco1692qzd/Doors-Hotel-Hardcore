local AchievementModule = game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game.RemoteListener.Modules.AchievementUnlock
if AchievementModule == nil then return end
if not game.ReplicatedStorage:FindFirstChild("ModulesShared") then return end
local dataModule = require(game:GetService("ReplicatedStorage"):WaitForChild("ModulesShared"):WaitForChild("Achievements"))
local unlockFunc = require(AchievementModule)
local function ImageLoader(url)
    if not (writefile and getcustomasset and request) then return nil end
    local rawUrl = url:gsub("github.com", "raw.githubusercontent.com"):gsub("/blob/", "/")
    local response = request({Url = rawUrl, Method = "GET"})
    if response.StatusCode ~= 200 then return nil end
    
    local fileName = "LoadedImageAchievement_" .. tick() .. ".png"
    writefile(fileName, response.Body)
    return getcustomasset(fileName)
end
local HardcoreSurvivorAchievement = "https://github.com/Francisco1692qzd/AchievementsImages/blob/main/Door100Achievement.png"
local Door100Image = ImageLoader(HardcoreSurvivorAchievement)

dataModule["HardcoreSurvivor"] = {
    GetInfo = function()
        return {
            Title = "HARDCORE SURVIVOR",
            Desc = "You survived the 100 rooms of Hardcore!",
            Reason = "Survive until Room 100. Congrats!",
            Image = Door100Image, -- Custom Icon ID
            --[[Prize = {
                Knobs = 50,
                Stardust = 10
            }--]]
        }
    end
}
dataModule["Rebound"] = {
	GetInfo = function()
		return {
			Title = "Many Reboundings",
			Desc = "I promise i will come back!",
			Reason = "Encounter Rebound.",
			Image = "rbxassetid://14889947785"
		}
	end
}
dataModule["Ripper"] = {
    GetInfo = function()
		return {
			Title = "Rip Apart",
			Desc = "Don't Leave Too Early.",
			Reason = "Encounter Ripper",
			Image = "rbxassetid://12231244908"
		}
    end)
}
dataModule["DeerGod"] = {
	GetInfo = function()
		return {
			Title = "Running for my life",
			Desc = "Why are you running?",
			Reason = "Encounter Dear God.",
			Image = "rbxassetid://11394027261"
		}
	end)
}
dataModule["Silence"] = {
	GetInfo = function()
		return {
			Title = "Eyes Closed Ears Open",
			Desc = "Better Hear or not",
			Reason = "Stay Silent to Encounter Silence!",
			Image = "rbxassetid://14168722837"
		}
	end)
}

--unlockFunc(nil, "Idiot")
print("Achievements Created Successfully")
