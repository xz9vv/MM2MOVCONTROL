--!nocheck
-----------------------------------
-- OPTIMIZATIONS MODULE
-----------------------------------
local Hub = getgenv().Hub
if not Hub then
	warn("[MM2 Hub] CoreState.lua must be loaded before Optimizations.lua!")
	return
end

local Services = Hub.Services
local Workspace = Services.Workspace
local SoundService = Services.SoundService
local PlayerGui = Hub.PlayerGui
local OptStates = Hub.OptStates
local Cache = Hub.Cache

-----------------------------------
-- PERSISTENT INSTANCE OPTIMIZER
-----------------------------------
local function applyPartOptimization(part)
	if not part or not part:IsA("BasePart") then return end
	if OptStates.SimplifyMaterials then
		if not Cache.Materials[part] then Cache.Materials[part] = part.Material end
		part.Material = Enum.Material.SmoothPlastic
	end
	if OptStates.ShadowKiller then
		part.CastShadow = false
	end
end

local function hookAnimator(animator)
	if not animator or not animator:IsA("Animator") then return end
	if not Cache.Connections[animator] then
		Cache.Connections[animator] = animator.AnimationPlayed:Connect(function(track)
			if OptStates.DeactivateAnims then track:AdjustSpeed(0) end
		end)
	end
	if OptStates.DeactivateAnims then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			track:AdjustSpeed(0)
		end
	end
end

-- Global Workspace & Sound Monitor
Workspace.DescendantAdded:Connect(function(obj)
	applyPartOptimization(obj)

	if OptStates.MuteAudio and obj:IsA("Sound") then
		if not Cache.Volumes[obj] then Cache.Volumes[obj] = obj.Volume end
		obj.Volume = 0
	end

	if OptStates.DeactivateAnims and obj:IsA("Animator") then
		hookAnimator(obj)
	end
end)

SoundService.DescendantAdded:Connect(function(obj)
	if OptStates.MuteAudio and obj:IsA("Sound") then
		if not Cache.Volumes[obj] then Cache.Volumes[obj] = obj.Volume end
		obj.Volume = 0
	end
end)

-- Persistent UI Visibility Monitor
local function monitorGui(gui)
	if not gui or not gui:IsA("ScreenGui") or gui.Name == "AdminDashboard" then return end
	if OptStates.HideUIs then
		if Cache.UIs[gui] == nil then Cache.UIs[gui] = gui.Enabled end
		gui.Enabled = false
	end

	if not Cache.Connections[gui] then
		Cache.Connections[gui] = gui:GetPropertyChangedSignal("Enabled"):Connect(function()
			if OptStates.HideUIs and gui.Name ~= "AdminDashboard" and gui.Enabled then
				gui.Enabled = false
			end
		end)
	end
end

for _, gui in ipairs(PlayerGui:GetChildren()) do monitorGui(gui) end
PlayerGui.ChildAdded:Connect(function(gui) monitorGui(gui) end)

Hub.ApplyPartOptimization = applyPartOptimization
Hub.HookAnimator = hookAnimator
Hub.MonitorGui = monitorGui

print("[MM2 Hub] Optimizations.lua loaded successfully!")
