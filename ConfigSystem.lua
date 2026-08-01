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
-- CONFIG MANAGEMENT HELPERS
-----------------------------------
function Hub.GetSerializedConfig()
	local botsToSave = {}
	for userId, isSelected in pairs(VisualSelectedBots) do
		if isSelected then
			local p = Players:GetPlayerByUserId(userId)
			local name = p and p.Name or "Unknown"
			table.insert(botsToSave, {UserId = userId, Name = name})
		end
	end
	
	return {
		OptStates = OptStates,
		Cache = {
			TweenSpeed = Cache.TweenSpeed,
			YOffset = Cache.YOffset,
			Use5YOffset = Cache.Use5YOffset
		},
		SelectedBots = botsToSave
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

	if data.SelectedBots then
		table.clear(VisualSelectedBots)
		for _, botInfo in ipairs(data.SelectedBots) do
			VisualSelectedBots[botInfo.UserId] = true
			for _, player in ipairs(Players:GetPlayers()) do
				if player.Name == botInfo.Name or player.UserId == botInfo.UserId then
					VisualSelectedBots[player.UserId] = true
				end
			end
		end
		if Hub.RefreshBotList then pcall(Hub.RefreshBotList) end
	end
end

function Hub.GetConfigsManifest()
	local manifest = {}
	pcall(function()
		if readfile and isfile and isfile("Dashboard_ConfigsManifest.json") then
			manifest = HttpService:JSONDecode(readfile("Dashboard_ConfigsManifest.json"))
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
