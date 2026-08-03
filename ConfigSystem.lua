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
-- BASE64 ENCODER & DECODER
-----------------------------------
local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

local function Base64Encode(data)
	return ((data:gsub('.', function(x) 
		local r,b='',x:byte()
		for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
		return r
	end)..'0000'):gsub('%d%d%d?%d?%d?', function(x)
		if (#x < 6) then return '' end
		local c=0
		for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
		return b64chars:sub(c+1,c+1)
	end)..({ '', '==', '=' })[#data%3+1])
end

local function Base64Decode(data)
	data = string.gsub(data, '[^'..b64chars..'=]', '')
	return (data:gsub('.', function(x)
		if (x == '=') then return '' end
		local r,f='',(b64chars:find(x)-1)
		for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
		return r
	end):gsub('%d%d%d%d%d%d%d%d', function(x)
		local c=0
		for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
		return string.char(c)
	end))
end

Hub.Base64Encode = Hub.Base64Encode or Base64Encode
Hub.Base64Decode = Hub.Base64Decode or Base64Decode

-----------------------------------
-- HELPER: USERNAME LIST PARSER
-----------------------------------
local function ParseUsernamesText(text)
	local usernames = {}
	if type(text) ~= "string" then return usernames end
	
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
	local rawText = Hub.BotUsernamesInputText or Hub.MasterBotUsernamesText or ""
	-- Sanitize newlines to spaces to prevent JSON control character errors
	local cleanRawText = rawText:gsub("[\r\n]+", " "):gsub("%s+", " ")
	local masterList = ParseUsernamesText(cleanRawText)
	
	if #masterList == 0 then
		for userId, isSelected in pairs(VisualSelectedBots) do
			if isSelected then
				local p = Players:GetPlayerByUserId(userId)
				if p and p.Name then
					table.insert(masterList, p.Name)
				end
			end
		end
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
		MasterUsernamesRaw = cleanRawText
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
		
		if data.MasterUsernamesRaw and #data.MasterUsernamesRaw > 0 then
			Hub.BotUsernamesInputText = data.MasterUsernamesRaw
		else
			Hub.BotUsernamesInputText = table.concat(usernamesToMatch, ", ")
		end
		
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
			manifest = HttpService:JSONDecode(readfile("Dashboard_ConfigsManifest.json"))
		end
	end)
	return (type(manifest) == "table") and manifest or {}
end

function Hub.SaveConfigToManifest(name)
	local manifest = Hub.GetConfigsManifest()
	if type(manifest) ~= "table" then manifest = {} end
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
