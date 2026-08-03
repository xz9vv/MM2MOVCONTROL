--!nocheck
-----------------------------------
-- CONFIG SYSTEM & SETTINGS MODULE
-----------------------------------
local Hub = getgenv().Hub
if not Hub then
	warn("[MM2 Hub] CoreState.lua must be loaded before ConfigSystem.lua!")
	return
end

local Services = Hub.Services
local Players = Services.Players
local TeleportService = Services.TeleportService
local HttpService = Services.HttpService

local LocalPlayer = Hub.LocalPlayer
local OptStates = Hub.OptStates
local Cache = Hub.Cache
local UIControls = Hub.UIControls
local VisualSelectedBots = Hub.VisualSelectedBots

-----------------------------------
-- HELPER: USERNAME LIST PARSER
-----------------------------------
local function ParseUsernamesText(text)
	local usernames = {}
	if type(text) ~= "string" then return usernames end
	
	-- Split by comma, newline, or whitespace
	for name in text:gmatch("[^,\r\n%s]+") do
		local cleanName = name:match("^%s*(.-)%s*$")
		if cleanName and #cleanName > 0 then
			table.insert(usernames, cleanName)
		end
	end
	return usernames
end

-----------------------------------
-- CONFIG MANAGEMENT HELPERS
-----------------------------------
function Hub.GetSerializedConfig()
	-- Read raw text from the Bot Usernames Textbox if available
	local rawText = Hub.BotUsernamesInputText or Hub.MasterBotUsernamesText or ""
	local masterList = ParseUsernamesText(rawText)
	
	-- Fallback: If textbox was empty, gather names from currently selected bots + LocalPlayer
	if #masterList == 0 then
		for userId, isSelected in pairs(VisualSelectedBots) do
			if isSelected then
				local p = Players:GetPlayerByUserId(userId)
				if p and p.Name then
					table.insert(masterList, p.Name)
				end
			end
		end
		-- Also ensure creator's name is in the saved list
		if LocalPlayer and LocalPlayer.Name and not table.find(masterList, LocalPlayer.Name) then
			table.insert(masterList, LocalPlayer.Name)
		end
	end
	
	return {
		OptStates = OptStates,
		Features = {
			CoinFarm = Cache.Connections["CoinFarmActive"] or false,
			CoinESP = Cache.Connections["ExpandHitboxes"] or false,
			BotSync = Cache.Connections["BotSyncActive"] or false,
		},
		Cache = {
			TweenSpeed = Cache.TweenSpeed,
			YOffset = Cache.YOffset,
			Use5YOffset = Cache.Use5YOffset
		},
		MasterUsernames = masterList,
		MasterUsernamesRaw = rawText
	}
end

function Hub.LoadConfigFromTable(data)
	if not data then return end
	
	local toggleMapping = {
		AntiIdle = "Anti-idle",
		ThreeDRender = "3D-Render Toggle",
		MuteAudio = "Mute Audio",
		SimplifyMaterials = "Simplify Materials",
		DeactivateAnims = "Deactivate Humanoid States",
		HideUIs = "UI Visibility Toggle",
		ShadowKiller = "Shadow Killer",
		PauseRenderQuality = "Pause 3D rendering",
		MemoryCleaner = "Memory Cleaner"
	}

	-- Load Optimizations
	if data.OptStates then
		for optKey, val in pairs(data.OptStates) do
			local uiName = toggleMapping[optKey]
			if uiName and UIControls.Toggles[uiName] then
				pcall(function() UIControls.Toggles[uiName](val) end)
			end
		end
		
		if data.OptStates.FPSLimit and UIControls.Sliders["FPS Limit"] then
			pcall(function() UIControls.Sliders["FPS Limit"](data.OptStates.FPSLimit) end)
		end
	end

	-- Load Features (Coin Farm, ESP, Bot Sync)
	if data.Features then
		if data.Features.CoinFarm ~= nil then
			if UIControls.Toggles["Auto Coin Farm"] then UIControls.Toggles["Auto Coin Farm"](data.Features.CoinFarm) end
			if Hub.StartCoinFarm then Hub.StartCoinFarm(data.Features.CoinFarm) end
		end
		if data.Features.CoinESP ~= nil then
			if UIControls.Toggles["Coin ESP Highlights"] then UIControls.Toggles["Coin ESP Highlights"](data.Features.CoinESP) end
			if Hub.StartCoinESP then Hub.StartCoinESP(data.Features.CoinESP) end
		end
		if data.Features.BotSync ~= nil then
			if UIControls.Toggles["Bot Communication Sync (Auto Pipeline)"] then UIControls.Toggles["Bot Communication Sync (Auto Pipeline)"](data.Features.BotSync) end
			if Hub.StartBotSync then Hub.StartBotSync(data.Features.BotSync) end
		end
	end
	
	-- Load Sliders
	if data.Cache then
		if data.Cache.TweenSpeed and UIControls.Sliders["Tween Speed"] then
			pcall(function() UIControls.Sliders["Tween Speed"](data.Cache.TweenSpeed) end)
		end
		if data.Cache.YOffset and UIControls.Sliders["Underground Offset"] then
			pcall(function() UIControls.Sliders["Underground Offset"](data.Cache.YOffset) end)
		end
		if data.Cache.Use5YOffset ~= nil and UIControls.Toggles["Use Underground Offset"] then
			pcall(function() UIControls.Toggles["Use Underground Offset"](data.Cache.Use5YOffset) end)
		end
	end

	-- Load Selected Bots from Master Usernames List
	local usernamesToMatch = data.MasterUsernames
	if not usernamesToMatch and data.SelectedBots then
		usernamesToMatch = {}
		for _, botInfo in ipairs(data.SelectedBots) do
			if type(botInfo) == "table" and botInfo.Name then
				table.insert(usernamesToMatch, botInfo.Name)
			elseif type(botInfo) == "string" then
				table.insert(usernamesToMatch, botInfo)
			end
		end
	end

	if usernamesToMatch then
		table.clear(VisualSelectedBots)
		
		-- Restore raw textbox string
		if data.MasterUsernamesRaw and #data.MasterUsernamesRaw > 0 then
			Hub.BotUsernamesInputText = data.MasterUsernamesRaw
		else
			Hub.BotUsernamesInputText = table.concat(usernamesToMatch, ", ")
		end
		
		-- Match any player in current server against the master list (excluding itself)
		for _, name in ipairs(usernamesToMatch) do
			local cleanTarget = name:lower():gsub("%s+", "")
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer then
					local playerName = player.Name:lower():gsub("%s+", "")
					if playerName == cleanTarget then
						VisualSelectedBots[player.UserId] = true
					end
				end
			end
		end
		
		if Hub.RefreshBotList then pcall(Hub.RefreshBotList) end
		if Hub.UpdateBotTextboxUI then pcall(Hub.UpdateBotTextboxUI) end
	end
end

function Hub.GetConfigsManifest()
	local manifest = {}
	pcall(function()
		if readfile and isfile and isfile("Dashboard_ConfigsManifest.json") then
			manifest = HttpService:JSONEncode(readfile("Dashboard_ConfigsManifest.json"))
		end
	end)
	return manifest
end

function Hub.SaveConfigToManifest(name)
	local manifest = Hub.GetConfigsManifest()
	if not table.find(manifest, name) then
		table.insert(manifest, name)
		pcall(function()
			if writefile then
				writefile("Dashboard_ConfigsManifest.json", HttpService:JSONEncode(manifest))
			end
		end)
	end
end

-----------------------------------
-- AUTO REJOIN HANDLER
-----------------------------------
function Hub.SetAutoRejoin(state)
	pcall(function() if writefile then writefile("Dashboard_AutoRejoin.txt", state and "true" or "false") end end)

	if state then
		Cache.Connections["AutoRejoinLoop"] = true
		task.spawn(function()
			local secondsWaited = 0
			while Cache.Connections["AutoRejoinLoop"] do
				task.wait(1)
				secondsWaited += 1
				
				if secondsWaited >= 2700 then
					if Cache.Connections["AutoRejoinLoop"] then
						pcall(function()
							local queue = queue_on_teleport or (syn and syn.queue_on_teleport)
							if queue then queue("pcall(function() writefile('Dashboard_AutoRejoin.txt', 'true') end)") end
						end)
						TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
					end
					break
				end
			end
		end)
	else
		Cache.Connections["AutoRejoinLoop"] = false
		pcall(function()
			if delfile and isfile and isfile("Dashboard_AutoRejoin.txt") then delfile("Dashboard_AutoRejoin.txt") end
		end)
	end
end

print("[MM2 Hub] ConfigSystem.lua loaded successfully!")
