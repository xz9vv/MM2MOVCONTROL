--!nocheck
-----------------------------------
-- UI FRAMEWORK & DASHBOARD MODULE
-----------------------------------
local Hub = getgenv().Hub
if not Hub then
	warn("[MM2 Hub] CoreState.lua must be loaded before UIFramework.lua!")
	return
end

local Services = Hub.Services
local Players = Services.Players
local RunService = Services.RunService
local UserInputService = Services.UserInputService
local Lighting = Services.Lighting
local TeleportService = Services.TeleportService
local HttpService = Services.HttpService

local LocalPlayer = Hub.LocalPlayer
local PlayerGui = Hub.PlayerGui
local OptStates = Hub.OptStates
local Cache = Hub.Cache
local Stats = Hub.Stats
local Theme = Hub.Theme
local UIControls = Hub.UIControls
local VisualSelectedBots = Hub.VisualSelectedBots

-----------------------------------
-- MAIN UI & BLACK OVERLAY SETUP
-----------------------------------
local dashboardGui = Instance.new("ScreenGui")
dashboardGui.Name = "AdminDashboard"
dashboardGui.ResetOnSpawn = false
dashboardGui.IgnoreGuiInset = true
dashboardGui.Parent = PlayerGui

local toggle3DRenderFunction = nil

-- 3D-RENDER BLACK SCREEN OVERLAY
local blackOverlay = Instance.new("Frame")
blackOverlay.Name = "BlackRenderOverlay"
blackOverlay.Size = UDim2.new(1, 0, 1, 0)
blackOverlay.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
blackOverlay.ZIndex = 200
blackOverlay.Visible = false
blackOverlay.Parent = dashboardGui

local overlayTitle = Instance.new("TextLabel")
overlayTitle.Size = UDim2.new(1, 0, 0, 50)
overlayTitle.Position = UDim2.new(0, 0, 0, 20)
overlayTitle.BackgroundTransparency = 1
overlayTitle.Text = "3D RENDERING OFF - LIVE STATISTICS"
overlayTitle.TextColor3 = Theme.AccentRed
overlayTitle.Font = Enum.Font.GothamBold
overlayTitle.TextSize = 20
overlayTitle.ZIndex = 201
overlayTitle.Parent = blackOverlay

local overlayStatsContainer = Instance.new("Frame")
overlayStatsContainer.Size = UDim2.new(0, 450, 0, 290)
overlayStatsContainer.Position = UDim2.new(0.5, -225, 0.5, -140)
overlayStatsContainer.BackgroundColor3 = Theme.Header
overlayStatsContainer.ZIndex = 201
overlayStatsContainer.Parent = blackOverlay
Instance.new("UICorner", overlayStatsContainer).CornerRadius = UDim.new(0, 8)

local overlayLayout = Instance.new("UIListLayout")
overlayLayout.SortOrder = Enum.SortOrder.LayoutOrder
overlayLayout.Padding = UDim.new(0, 5)
overlayLayout.Parent = overlayStatsContainer

local overlayPadding = Instance.new("UIPadding")
overlayPadding.PaddingLeft = UDim.new(0, 20)
overlayPadding.PaddingTop = UDim.new(0, 15)
overlayPadding.Parent = overlayStatsContainer

local function createOverlayLabel(text, color, order)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -30, 0, 22)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = color or Theme.TextActive
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.LayoutOrder = order
	lbl.ZIndex = 202
	lbl.Parent = overlayStatsContainer
	return lbl
end

local overlayMurdererLbl = createOverlayLabel("Murderer: None", Theme.RoleRed, 1)
local overlaySheriffLbl = createOverlayLabel("Sheriff: None", Theme.RoleBlue, 2)
local overlayRoleLbl = createOverlayLabel("You are: INNOCENT", Theme.TextActive, 3)
local overlayLobbyLbl = createOverlayLabel("In Lobby: true", Theme.TextNormal, 4)
local overlaySquadLbl = createOverlayLabel("Squad Ready: 1/1", Theme.TextNormal, 5)
local overlayAllReadyLbl = createOverlayLabel("All Ready: false", Theme.TextNormal, 6)
local overlayCoinsLbl = createOverlayLabel("Coins in Bag: 0/40", Theme.TextActive, 7)
local overlayLastRoundLbl = createOverlayLabel("Made last round: 0", Theme.TextNormal, 8)
local overlayTotalCoinsLbl = createOverlayLabel("Total coins farmed: 0", Theme.TextActive, 9)

local exitUnrenderedBtn = Instance.new("TextButton")
exitUnrenderedBtn.Size = UDim2.new(1, -40, 0, 32)
exitUnrenderedBtn.BackgroundColor3 = Theme.AccentRed
exitUnrenderedBtn.Text = "Reopen Control Panel (Enable 3D Render)"
exitUnrenderedBtn.TextColor3 = Theme.TextActive
exitUnrenderedBtn.Font = Enum.Font.GothamBold
exitUnrenderedBtn.TextSize = 13
exitUnrenderedBtn.LayoutOrder = 10
exitUnrenderedBtn.ZIndex = 203
exitUnrenderedBtn.Parent = overlayStatsContainer
Instance.new("UICorner", exitUnrenderedBtn).CornerRadius = UDim.new(0, 6)

-- Main Window Setup
local mainWindow = Instance.new("Frame")
mainWindow.Name = "MainWindow"
mainWindow.Size = UDim2.new(0, 650, 0, 380)
mainWindow.Position = UDim2.new(0.5, -325, 0.5, -190)
mainWindow.BackgroundColor3 = Theme.Background
mainWindow.Parent = dashboardGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainWindow

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Theme.Border
mainStroke.Thickness = 1
mainStroke.Parent = mainWindow

-- Header Bar
local headerBar = Instance.new("Frame")
headerBar.Size = UDim2.new(1, 0, 0, 40)
headerBar.BackgroundColor3 = Theme.Header
headerBar.Parent = mainWindow

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 8)
headerCorner.Parent = headerBar

local headerBlend = Instance.new("Frame")
headerBlend.Size = UDim2.new(1, 0, 0, 10)
headerBlend.Position = UDim2.new(0, 0, 1, -10)
headerBlend.BackgroundColor3 = Theme.Header
headerBlend.BorderSizePixel = 0
headerBlend.Parent = headerBar

-- Dragging Logic
local dragging, dragInput, dragStart, startPos
headerBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainWindow.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
RunService.RenderStepped:Connect(function()
	if dragging and dragInput then
		local delta = dragInput.Position - dragStart
		mainWindow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-----------------------------------
-- MINIMIZE & CLOSE CONTROLS
-----------------------------------
local controlsFrame = Instance.new("Frame")
controlsFrame.Size = UDim2.new(0, 80, 0, 30)
controlsFrame.Position = UDim2.new(1, -85, 0, 5)
controlsFrame.BackgroundTransparency = 1
controlsFrame.ZIndex = 10
controlsFrame.Parent = headerBar

local btnMin = Instance.new("TextButton")
btnMin.Size = UDim2.new(0.5, 0, 1, 0)
btnMin.BackgroundTransparency = 1
btnMin.Text = "—"
btnMin.TextColor3 = Theme.TextNormal
btnMin.Font = Enum.Font.GothamMedium
btnMin.TextSize = 14
btnMin.ZIndex = 10
btnMin.Parent = controlsFrame

local btnClose = Instance.new("TextButton")
btnClose.Size = UDim2.new(0.5, 0, 1, 0)
btnClose.Position = UDim2.new(0.5, 0, 0, 0)
btnClose.BackgroundTransparency = 1
btnClose.Text = "X"
btnClose.TextColor3 = Theme.TextNormal
btnClose.Font = Enum.Font.GothamMedium
btnClose.TextSize = 14
btnClose.ZIndex = 10
btnClose.Parent = controlsFrame

local restoreBtn = Instance.new("TextButton")
restoreBtn.Size = UDim2.new(0, 45, 0, 45)
restoreBtn.Position = UDim2.new(1, -65, 0.75, 0)
restoreBtn.BackgroundColor3 = Theme.Background
restoreBtn.Text = "□"
restoreBtn.TextColor3 = Theme.AccentRed
restoreBtn.Font = Enum.Font.GothamMedium
restoreBtn.TextSize = 20
restoreBtn.Visible = false
restoreBtn.Parent = dashboardGui

Instance.new("UICorner", restoreBtn).CornerRadius = UDim.new(0, 8)
local restoreStroke = Instance.new("UIStroke")
restoreStroke.Color = Theme.AccentRed
restoreStroke.Parent = restoreBtn

btnMin.MouseButton1Click:Connect(function()
	mainWindow.Visible = false
	restoreBtn.Visible = true
end)

restoreBtn.MouseButton1Click:Connect(function()
	mainWindow.Visible = true
	restoreBtn.Visible = false
end)

-- Revert and Close Logic
local function revertAllChanges()
	OptStates.SimplifyMaterials = false
	OptStates.ShadowKiller = false
	OptStates.MuteAudio = false
	OptStates.DeactivateAnims = false
	OptStates.HideUIs = false
	OptStates.ThreeDRender = false

	Cache.Connections["CoinFarmActive"] = false
	Cache.Connections["ExpandHitboxes"] = false
	Cache.Connections["MM2CleanerActive"] = false
	Cache.Connections["AutoRejoinLoop"] = false
	Cache.Connections["BotSyncActive"] = false
	
	if Cache.CurrentTween then
		pcall(function() Cache.CurrentTween:Cancel() Cache.CurrentTween:Destroy() end)
		Cache.CurrentTween = nil
	end
	
	Hub.SetNoclip(false)
	
	for obj, vol in pairs(Cache.Volumes) do
		if obj and obj.Parent then obj.Volume = vol end
	end
	for obj, mat in pairs(Cache.Materials) do
		if obj and obj.Parent then obj.Material = mat; obj.CastShadow = true end
	end
	for ui, state in pairs(Cache.UIs) do
		if ui and ui.Parent then ui.Enabled = state end
	end
	
	pcall(function() RunService:Set3dRenderingEnabled(true) end)
	pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
	Lighting.GlobalShadows = true
	
	for _, conn in pairs(Cache.Connections) do 
		if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end 
	end
	dashboardGui:Destroy()
end

-- Close Confirmation Overlay
local confirmOverlay = Instance.new("Frame")
confirmOverlay.Size = UDim2.new(1, 0, 1, 0)
confirmOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
confirmOverlay.BackgroundTransparency = 0.4
confirmOverlay.Visible = false
confirmOverlay.Active = true
confirmOverlay.ZIndex = 50
confirmOverlay.Parent = dashboardGui

local confirmBox = Instance.new("Frame")
confirmBox.Size = UDim2.new(0, 320, 0, 130)
confirmBox.Position = UDim2.new(0.5, -160, 0.5, -65)
confirmBox.BackgroundColor3 = Theme.Background
confirmBox.ZIndex = 51
confirmBox.Parent = confirmOverlay
Instance.new("UICorner", confirmBox).CornerRadius = UDim.new(0, 8)

local confirmText = Instance.new("TextLabel")
confirmText.Size = UDim2.new(1, 0, 0, 70)
confirmText.BackgroundTransparency = 1
confirmText.Text = "Close and revert all optimizations?"
confirmText.TextColor3 = Theme.TextActive
confirmText.Font = Enum.Font.GothamMedium
confirmText.TextSize = 15
confirmText.ZIndex = 52
confirmText.Parent = confirmBox

local btnYes = Instance.new("TextButton")
btnYes.Size = UDim2.new(0, 110, 0, 35)
btnYes.Position = UDim2.new(0, 40, 0, 75)
btnYes.BackgroundColor3 = Theme.AccentRed
btnYes.Text = "Yes"
btnYes.TextColor3 = Theme.TextActive
btnYes.Font = Enum.Font.GothamMedium
btnYes.ZIndex = 52
btnYes.Parent = confirmBox
Instance.new("UICorner", btnYes).CornerRadius = UDim.new(0, 4)

local btnNo = Instance.new("TextButton")
btnNo.Size = UDim2.new(0, 110, 0, 35)
btnNo.Position = UDim2.new(0, 170, 0, 75)
btnNo.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
btnNo.Text = "Cancel"
btnNo.TextColor3 = Theme.TextActive
btnNo.Font = Enum.Font.GothamMedium
btnNo.ZIndex = 52
btnNo.Parent = confirmBox
Instance.new("UICorner", btnNo).CornerRadius = UDim.new(0, 4)

btnClose.MouseButton1Click:Connect(function() confirmOverlay.Visible = true end)
btnNo.MouseButton1Click:Connect(function() confirmOverlay.Visible = false end)
btnYes.MouseButton1Click:Connect(revertAllChanges)

-----------------------------------
-- TAB SYSTEM
-----------------------------------
local tabs = {"Main", "Misc", "Optimization", "Config", "Settings"}
local tabFrames = {}

local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(0, 540, 1, 0)
tabContainer.Position = UDim2.new(0, 10, 0, 0)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = headerBar

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 6)
tabLayout.Parent = tabContainer

local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, 0, 1, -40)
contentContainer.Position = UDim2.new(0, 0, 0, 40)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = mainWindow

for i, tabName in ipairs(tabs) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 95, 0, 30)
	btn.Position = UDim2.new(0, 0, 0, 5)
	btn.BackgroundColor3 = Theme.TabBackground
	btn.Text = tabName
	btn.TextColor3 = (tabName == "Main") and Theme.TextActive or Theme.TextNormal
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 13
	btn.LayoutOrder = i
	btn.Parent = tabContainer
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
	
	local underline = Instance.new("Frame")
	underline.Size = UDim2.new(1, 0, 0, 2)
	underline.Position = UDim2.new(0, 0, 1, 0)
	underline.BackgroundColor3 = Theme.AccentRed
	underline.Visible = (tabName == "Main")
	underline.Parent = btn

	local viewFrame = Instance.new("ScrollingFrame")
	viewFrame.ScrollBarThickness = 6
	viewFrame.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
	viewFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = viewFrame
	
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		viewFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
	end)
	
	viewFrame.Name = tabName .. "View"
	viewFrame.Size = UDim2.new(1, -40, 1, -20)
	viewFrame.Position = UDim2.new(0, 20, 0, 10)
	viewFrame.BackgroundTransparency = 1
	viewFrame.Visible = (tabName == "Main")
	viewFrame.Parent = contentContainer

	tabFrames[tabName] = {Btn = btn, Underline = underline, View = viewFrame}
	
	btn.MouseButton1Click:Connect(function()
		for name, data in pairs(tabFrames) do
			local isActive = (name == tabName)
			data.View.Visible = isActive
			data.Underline.Visible = isActive
			data.Btn.TextColor3 = isActive and Theme.TextActive or Theme.TextNormal
		end
	end)
end

-----------------------------------
-- MISC TAB LIVE DASHBOARD BUILDER
-----------------------------------
local miscView = tabFrames["Misc"].View

local function createMiscLabel(text, color, order)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -15, 0, 26)
	lbl.BackgroundColor3 = Theme.TabBackground
	lbl.Text = "  " .. text
	lbl.TextColor3 = color or Theme.TextActive
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.LayoutOrder = order
	lbl.Parent = miscView
	Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 6)
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Border
	stroke.Thickness = 1
	stroke.Parent = lbl
	return lbl
end

local miscMurdererLbl = createMiscLabel("Murderer: None", Theme.RoleRed, 1)
local miscSheriffLbl = createMiscLabel("Sheriff: None", Theme.RoleBlue, 2)
local miscRoleLbl = createMiscLabel("You are: INNOCENT", Theme.TextActive, 3)
local miscLobbyLbl = createMiscLabel("In Lobby: true", Theme.TextNormal, 4)
local miscSquadLbl = createMiscLabel("Squad Ready: 1/1", Theme.TextNormal, 5)
local miscAllReadyLbl = createMiscLabel("All Ready: false", Theme.TextNormal, 6)
local miscCoinsLbl = createMiscLabel("Coins in Bag: 0/40", Theme.TextActive, 7)
local miscLastRoundLbl = createMiscLabel("Made last round: 0", Theme.TextNormal, 8)
local miscTotalCoinsLbl = createMiscLabel("Total coins farmed: 0", Theme.TextActive, 9)

-----------------------------------
-- REAL-TIME STATS UPDATER LOOP
-----------------------------------
task.spawn(function()
	while true do
		task.wait(0.3)

		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")

		Stats.InLobby = Hub.IsPlayerInLobby(hrp)
		Stats.CurrentRole = Hub.GetLocalPlayerRole()

		local murdPlayer = Hub.GetPublicMurderer()
		Stats.MurdererName = murdPlayer and murdPlayer.DisplayName or "None"

		local sherPlayer = Hub.GetPublicSheriff()
		Stats.SheriffName = sherPlayer and sherPlayer.DisplayName or "None"

		local currentCoins = Hub.GetCurrentCoinCount()
		if currentCoins < Stats.LastBagCount and Stats.LastBagCount >= 5 then
			Stats.CoinsLastRound = Stats.LastBagCount
			Stats.TotalCoinsFarmed = Stats.TotalCoinsFarmed + Stats.LastBagCount
		end
		Stats.LastBagCount = currentCoins
		Stats.CoinsInBag = currentCoins

		local murdTxt = "  Murderer: " .. Stats.MurdererName
		local sherTxt = "  Sheriff: " .. Stats.SheriffName
		local roleTxt = "  You are: " .. Stats.CurrentRole
		local lobbyTxt = "  In Lobby: " .. tostring(Stats.InLobby)
		local squadTxt = "  Squad Ready: " .. Stats.SquadReadyText
		local readyTxt = "  All Ready: " .. tostring(Stats.AllReady)
		local coinsTxt = "  Coins in Bag: " .. tostring(Stats.CoinsInBag) .. "/40"
		local lastTxt = "  Made last round: " .. tostring(Stats.CoinsLastRound)
		local totalTxt = "  Total coins farmed: " .. tostring(Stats.TotalCoinsFarmed)

		miscMurdererLbl.Text = murdTxt
		miscSheriffLbl.Text = sherTxt
		miscRoleLbl.Text = roleTxt
		miscLobbyLbl.Text = lobbyTxt
		miscSquadLbl.Text = squadTxt
		miscAllReadyLbl.Text = readyTxt
		miscCoinsLbl.Text = coinsTxt
		miscLastRoundLbl.Text = lastTxt
		miscTotalCoinsLbl.Text = totalTxt

		overlayMurdererLbl.Text = murdTxt
		overlaySheriffLbl.Text = sherTxt
		overlayRoleLbl.Text = roleTxt
		overlayLobbyLbl.Text = lobbyTxt
		overlaySquadLbl.Text = squadTxt
		overlayAllReadyLbl.Text = readyTxt
		overlayCoinsLbl.Text = coinsTxt
		overlayLastRoundLbl.Text = lastTxt
		overlayTotalCoinsLbl.Text = totalTxt
	end
end)

-----------------------------------
-- UI BUILDER HELPERS
-----------------------------------
local function createDropdownSection(parentView, sectionTitle, layoutOrder)
	local sectionFrame = Instance.new("Frame")
	sectionFrame.Size = UDim2.new(1, -15, 0, 36)
	sectionFrame.BackgroundColor3 = Theme.TabBackground
	sectionFrame.ClipsDescendants = true
	sectionFrame.LayoutOrder = layoutOrder
	sectionFrame.Parent = parentView
	Instance.new("UICorner", sectionFrame).CornerRadius = UDim.new(0, 6)
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Border
	stroke.Thickness = 1
	stroke.Parent = sectionFrame

	local headerBtn = Instance.new("TextButton")
	headerBtn.Size = UDim2.new(1, 0, 0, 36)
	headerBtn.BackgroundTransparency = 1
	headerBtn.Text = sectionTitle .. "  ▼"
	headerBtn.TextColor3 = Theme.TextActive
	headerBtn.Font = Enum.Font.GothamBold
	headerBtn.TextSize = 14
	headerBtn.TextXAlignment = Enum.TextXAlignment.Left
	headerBtn.Parent = sectionFrame
	
	local headerPadding = Instance.new("UIPadding")
	headerPadding.PaddingLeft = UDim.new(0, 15)
	headerPadding.Parent = headerBtn

	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 0)
	container.Position = UDim2.new(0, 0, 0, 36)
	container.BackgroundTransparency = 1
	container.Parent = sectionFrame
	
	local containerLayout = Instance.new("UIListLayout")
	containerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	containerLayout.Padding = UDim.new(0, 6)
	containerLayout.Parent = container

	local isOpen = false
	local function updateSize()
		if isOpen then
			local contentHeight = containerLayout.AbsoluteContentSize.Y + 10
			sectionFrame.Size = UDim2.new(1, -15, 0, 36 + contentHeight)
			container.Size = UDim2.new(1, 0, 0, contentHeight)
			headerBtn.Text = sectionTitle .. "  ▲"
		else
			sectionFrame.Size = UDim2.new(1, -15, 0, 36)
			container.Size = UDim2.new(1, 0, 0, 0)
			headerBtn.Text = sectionTitle .. "  ▼"
		end
	end

	containerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSize)
	headerBtn.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		updateSize()
	end)

	return container
end

local function createSectionToggle(parentContainer, text, layoutOrder, defaultState, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -20, 0, 32)
	btn.Position = UDim2.new(0, 10, 0, 0)
	btn.BackgroundColor3 = defaultState and Theme.ToggleOn_Bg or Theme.ToggleOff_Bg
	btn.Text = text
	btn.TextColor3 = defaultState and Theme.ToggleOn_Text or Theme.ToggleOff_Text
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 13
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.LayoutOrder = layoutOrder
	btn.Parent = parentContainer
	
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 15)
	padding.Parent = btn
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.ToggleOn_Stroke
	stroke.Thickness = 1.5
	stroke.Transparency = defaultState and 0 or 1 
	stroke.Parent = btn
	
	local isOn = defaultState or false
	local function setToggleState(state)
		isOn = state
		btn.BackgroundColor3 = isOn and Theme.ToggleOn_Bg or Theme.ToggleOff_Bg
		btn.TextColor3 = isOn and Theme.ToggleOn_Text or Theme.ToggleOff_Text
		stroke.Transparency = isOn and 0 or 1
		callback(isOn, btn)
	end

	btn.MouseButton1Click:Connect(function()
		setToggleState(not isOn)
	end)

	UIControls.Toggles[text] = setToggleState
	return btn
end

local function createSectionSlider(parentContainer, text, minVal, maxVal, defaultVal, layoutOrder, callback)
	local sliderFrame = Instance.new("Frame")
	sliderFrame.Size = UDim2.new(1, -20, 0, 45)
	sliderFrame.BackgroundColor3 = Theme.ToggleOff_Bg
	sliderFrame.LayoutOrder = layoutOrder
	sliderFrame.Parent = parentContainer
	Instance.new("UICorner", sliderFrame).CornerRadius = UDim.new(0, 6)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -30, 0, 20)
	titleLabel.Position = UDim2.new(0, 15, 0, 4)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = text .. ": " .. tostring(defaultVal)
	titleLabel.TextColor3 = Theme.TextActive
	titleLabel.Font = Enum.Font.GothamMedium
	titleLabel.TextSize = 13
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = sliderFrame

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -30, 0, 8)
	track.Position = UDim2.new(0, 15, 0, 28)
	track.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	track.Parent = sliderFrame
	Instance.new("UICorner", track).CornerRadius = UDim.new(0, 4)

	local fill = Instance.new("Frame")
	local initScale = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)
	fill.Size = UDim2.new(initScale, 0, 1, 0)
	fill.BackgroundColor3 = Theme.AccentRed
	fill.Parent = track
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

	local function setValue(value)
		value = math.clamp(value, minVal, maxVal)
		local percentage = (value - minVal) / (maxVal - minVal)
		fill.Size = UDim2.new(percentage, 0, 1, 0)
		titleLabel.Text = text .. ": " .. tostring(value)
		callback(value)
	end

	local draggingSlider = false
	local function updateSlider(input)
		local posX = input.Position.X - track.AbsolutePosition.X
		local percentage = math.clamp(posX / track.AbsoluteSize.X, 0, 1)
		local value = math.floor(minVal + (maxVal - minVal) * percentage)
		setValue(value)
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSlider = true
			updateSlider(input)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateSlider(input)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSlider = false
		end
	end)

	UIControls.Sliders[text] = setValue
end

-----------------------------------
-- MAIN TAB BUILDER
-----------------------------------
local mainView = tabFrames["Main"].View

local coinFarmSection = createDropdownSection(mainView, "COIN FARM", 1)
local hitboxesSection = createDropdownSection(mainView, "HITBOXES", 2)
local botsSection = createDropdownSection(mainView, "BOTS", 3)

createSectionToggle(coinFarmSection, "Auto Coin Farm", 1, false, function(state)
	if Hub.StartCoinFarm then Hub.StartCoinFarm(state) end
end)

createSectionToggle(coinFarmSection, "Use Underground Offset", 2, true, function(state)
	Cache.Use5YOffset = state
end)

createSectionSlider(coinFarmSection, "Underground Offset", 0, 15, 2, 3, function(value)
	Cache.YOffset = value
end)

createSectionSlider(coinFarmSection, "Tween Speed", 10, 100, 20, 4, function(value)
	Cache.TweenSpeed = value
	if Cache.CurrentTween then
		pcall(function() Cache.CurrentTween:Cancel() Cache.CurrentTween:Destroy() end)
		Cache.CurrentTween = nil
	end
end)

createSectionToggle(hitboxesSection, "Coin ESP Highlights", 1, false, function(state)
	if Hub.StartCoinESP then Hub.StartCoinESP(state) end
end)

createSectionToggle(botsSection, "Bot Communication Sync (Auto Pipeline)", 1, false, function(state)
	if Hub.StartBotSync then Hub.StartBotSync(state) end
end)

-- Bot UI Inputs
local botUsernameInput = Instance.new("TextBox")
botUsernameInput.Size = UDim2.new(1, -20, 0, 32)
botUsernameInput.Position = UDim2.new(0, 10, 0, 0)
botUsernameInput.BackgroundColor3 = Theme.TabBackground
botUsernameInput.PlaceholderText = "Paste Bot Usernames (comma or newline separated)"
botUsernameInput.Text = ""
botUsernameInput.TextColor3 = Theme.TextActive
botUsernameInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
botUsernameInput.Font = Enum.Font.GothamMedium
botUsernameInput.TextSize = 12
botUsernameInput.LayoutOrder = 2
botUsernameInput.Parent = botsSection
Instance.new("UICorner", botUsernameInput).CornerRadius = UDim.new(0, 6)

local importStroke = Instance.new("UIStroke")
importStroke.Color = Theme.Border
importStroke.Thickness = 1
importStroke.Parent = botUsernameInput

local importBotsBtn = Instance.new("TextButton")
importBotsBtn.Size = UDim2.new(1, -20, 0, 28)
importBotsBtn.Position = UDim2.new(0, 10, 0, 0)
importBotsBtn.BackgroundColor3 = Theme.ToggleOn_Bg
importBotsBtn.Text = "Import & Select Bots"
importBotsBtn.TextColor3 = Theme.ToggleOn_Text
importBotsBtn.Font = Enum.Font.GothamMedium
importBotsBtn.TextSize = 12
importBotsBtn.LayoutOrder = 3
importBotsBtn.Parent = botsSection
Instance.new("UICorner", importBotsBtn).CornerRadius = UDim.new(0, 4)

local importBtnStroke = Instance.new("UIStroke")
importBtnStroke.Color = Theme.ToggleOn_Stroke
importBtnStroke.Thickness = 1
importBtnStroke.Parent = importBotsBtn

local botListToggleBtn = Instance.new("TextButton")
botListToggleBtn.Size = UDim2.new(1, -20, 0, 30)
botListToggleBtn.Position = UDim2.new(0, 10, 0, 0)
botListToggleBtn.BackgroundColor3 = Theme.TabBackground
botListToggleBtn.Text = "Select Bots List  ▼"
botListToggleBtn.TextColor3 = Theme.TextActive
botListToggleBtn.Font = Enum.Font.GothamMedium
botListToggleBtn.TextSize = 12
botListToggleBtn.LayoutOrder = 4
botListToggleBtn.Parent = botsSection
Instance.new("UICorner", botListToggleBtn).CornerRadius = UDim.new(0, 4)

local botListContainer = Instance.new("Frame")
botListContainer.Size = UDim2.new(1, -20, 0, 0)
botListContainer.Position = UDim2.new(0, 10, 0, 0)
botListContainer.BackgroundTransparency = 1
botListContainer.Visible = false
botListContainer.LayoutOrder = 5
botListContainer.Parent = botsSection

local botListLayout = Instance.new("UIListLayout")
botListLayout.SortOrder = Enum.SortOrder.LayoutOrder
botListLayout.Padding = UDim.new(0, 4)
botListLayout.Parent = botListContainer

botListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	botListContainer.Size = UDim2.new(1, -20, 0, botListLayout.AbsoluteContentSize.Y)
end)

local botListOpen = false
botListToggleBtn.MouseButton1Click:Connect(function()
	botListOpen = not botListOpen
	botListContainer.Visible = botListOpen
	botListToggleBtn.Text = botListOpen and "Select Bots List  ▲" or "Select Bots List  ▼"
end)

local function refreshBotList()
	for _, child in ipairs(botListContainer:GetChildren()) do
		if not child:IsA("UIListLayout") then child:Destroy() end
	end

	for i, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local isSelected = VisualSelectedBots[player.UserId] or false
			
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, 0, 0, 28)
			btn.BackgroundColor3 = isSelected and Theme.ToggleOn_Bg or Theme.ToggleOff_Bg
			btn.Text = "Bot: " .. player.DisplayName .. " (@" .. player.Name .. ")"
			btn.TextColor3 = isSelected and Theme.ToggleOn_Text or Theme.ToggleOff_Text
			btn.Font = Enum.Font.GothamMedium
			btn.TextSize = 12
			btn.TextXAlignment = Enum.TextXAlignment.Left
			btn.LayoutOrder = i
			btn.Parent = botListContainer
			
			local padding = Instance.new("UIPadding")
			padding.PaddingLeft = UDim.new(0, 10)
			padding.Parent = btn
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
			
			local stroke = Instance.new("UIStroke")
			stroke.Color = Theme.ToggleOn_Stroke
			stroke.Thickness = 1
			stroke.Transparency = isSelected and 0 or 1
			stroke.Parent = btn

			btn.MouseButton1Click:Connect(function()
				isSelected = not isSelected
				VisualSelectedBots[player.UserId] = isSelected
				btn.BackgroundColor3 = isSelected and Theme.ToggleOn_Bg or Theme.ToggleOff_Bg
				btn.TextColor3 = isSelected and Theme.ToggleOn_Text or Theme.ToggleOff_Text
				stroke.Transparency = isSelected and 0 or 1
			end)
		end
	end
end

Hub.RefreshBotList = refreshBotList

importBotsBtn.MouseButton1Click:Connect(function()
	local text = botUsernameInput.Text
	if text == "" then return end
	
	local targets = {}
	for word in string.gmatch(text, "[%w_]+") do
		table.insert(targets, word:lower())
	end
	
	local importedCount = 0
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local uName = player.Name:lower()
			local dName = player.DisplayName:lower()
			for _, target in ipairs(targets) do
				if uName == target or dName == target then
					VisualSelectedBots[player.UserId] = true
					importedCount = importedCount + 1
					break
				end
			end
		end
	end
	
	importBotsBtn.Text = "Imported " .. tostring(importedCount) .. " Bots!"
	task.delay(2, function()
		importBotsBtn.Text = "Import & Select Bots"
	end)
	
	refreshBotList()
end)

local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(1, -20, 0, 28)
refreshBtn.Position = UDim2.new(0, 10, 0, 0)
refreshBtn.BackgroundColor3 = Theme.TabBackground
refreshBtn.Text = "Refresh Server Bot List"
refreshBtn.TextColor3 = Theme.TextActive
refreshBtn.Font = Enum.Font.GothamMedium
refreshBtn.TextSize = 12
refreshBtn.LayoutOrder = 6
refreshBtn.Parent = botsSection
Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 4)

refreshBtn.MouseButton1Click:Connect(refreshBotList)

-----------------------------------
-- OPTIMIZATION TAB BUILDER
-----------------------------------
local optimizationView = tabFrames["Optimization"].View

local function createToggle(text, layoutOrder, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -15, 0, 32)
	btn.BackgroundColor3 = Theme.ToggleOff_Bg
	btn.Text = text
	btn.TextColor3 = Theme.ToggleOff_Text
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 14
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.LayoutOrder = layoutOrder
	btn.Parent = optimizationView
	
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 15)
	padding.Parent = btn
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.ToggleOn_Stroke
	stroke.Thickness = 1.5
	stroke.Transparency = 1 
	stroke.Parent = btn
	
	local isOn = false
	local function setToggleState(state)
		isOn = state
		btn.BackgroundColor3 = isOn and Theme.ToggleOn_Bg or Theme.ToggleOff_Bg
		btn.TextColor3 = isOn and Theme.ToggleOn_Text or Theme.ToggleOff_Text
		stroke.Transparency = isOn and 0 or 1
		callback(isOn, btn)
	end

	btn.MouseButton1Click:Connect(function()
		setToggleState(not isOn)
	end)

	UIControls.Toggles[text] = setToggleState
	return setToggleState
end

local function createOptimizationSlider(text, minVal, maxVal, defaultVal, layoutOrder, callback)
	local sliderFrame = Instance.new("Frame")
	sliderFrame.Size = UDim2.new(1, -15, 0, 45)
	sliderFrame.BackgroundColor3 = Theme.ToggleOff_Bg
	sliderFrame.LayoutOrder = layoutOrder
	sliderFrame.Parent = optimizationView
	Instance.new("UICorner", sliderFrame).CornerRadius = UDim.new(0, 6)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -30, 0, 20)
	titleLabel.Position = UDim2.new(0, 15, 0, 4)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = text .. ": " .. tostring(defaultVal)
	titleLabel.TextColor3 = Theme.TextActive
	titleLabel.Font = Enum.Font.GothamMedium
	titleLabel.TextSize = 13
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = sliderFrame

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -30, 0, 8)
	track.Position = UDim2.new(0, 15, 0, 28)
	track.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	track.Parent = sliderFrame
	Instance.new("UICorner", track).CornerRadius = UDim.new(0, 4)

	local fill = Instance.new("Frame")
	local initScale = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)
	fill.Size = UDim2.new(initScale, 0, 1, 0)
	fill.BackgroundColor3 = Theme.AccentRed
	fill.Parent = track
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

	local function setValue(value)
		value = math.clamp(value, minVal, maxVal)
		local percentage = (value - minVal) / (maxVal - minVal)
		fill.Size = UDim2.new(percentage, 0, 1, 0)
		titleLabel.Text = text .. ": " .. tostring(value)
		callback(value)
	end

	local draggingSlider = false
	local function updateSlider(input)
		local posX = input.Position.X - track.AbsolutePosition.X
		local percentage = math.clamp(posX / track.AbsoluteSize.X, 0, 1)
		local value = math.floor(minVal + (maxVal - minVal) * percentage)
		setValue(value)
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSlider = true
			updateSlider(input)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateSlider(input)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSlider = false
		end
	end)

	UIControls.Sliders[text] = setValue
end

createToggle("Anti-idle", 1, function(state)
	OptStates.AntiIdle = state
	if state then
		local VirtualUser = game:GetService("VirtualUser")
		Cache.Connections["AntiIdle"] = LocalPlayer.Idled:Connect(function()
			VirtualUser:Button2Down(Vector2.new(0,0), Services.Workspace.CurrentCamera.CFrame)
			task.wait(0.1)
			VirtualUser:Button2Up(Vector2.new(0,0), Services.Workspace.CurrentCamera.CFrame)
		end)
	else
		if Cache.Connections["AntiIdle"] then
			Cache.Connections["AntiIdle"]:Disconnect()
			Cache.Connections["AntiIdle"] = nil
		end
	end
end)

toggle3DRenderFunction = createToggle("3D-Render Toggle", 2, function(state)
	OptStates.ThreeDRender = state
	pcall(function() RunService:Set3dRenderingEnabled(not state) end)
	blackOverlay.Visible = state
	mainWindow.Visible = not state
end)

exitUnrenderedBtn.MouseButton1Click:Connect(function()
	if toggle3DRenderFunction then toggle3DRenderFunction(false) end
end)

createOptimizationSlider("FPS Limit", 1, 180, 60, 3, function(value)
	OptStates.FPSLimit = value
	pcall(function() if setfpscap then setfpscap(value) end end)
end)

createToggle("Mute Audio", 4, function(state)
	OptStates.MuteAudio = state
	if state then
		task.spawn(function()
			local count = 0
			for _, obj in ipairs(Services.SoundService:GetDescendants()) do
				if obj:IsA("Sound") then
					if not Cache.Volumes[obj] then Cache.Volumes[obj] = obj.Volume end
					obj.Volume = 0
				end
			end
			for _, obj in ipairs(Services.Workspace:GetDescendants()) do
				if obj:IsA("Sound") then
					if not Cache.Volumes[obj] then Cache.Volumes[obj] = obj.Volume end
					obj.Volume = 0
				end
				count += 1
				if count % 250 == 0 then task.wait() end 
			end
		end)
	else
		for obj, vol in pairs(Cache.Volumes) do
			if obj and obj.Parent then obj.Volume = vol end
		end
	end
end)

createToggle("Simplify Materials", 5, function(state)
	OptStates.SimplifyMaterials = state
	if state then
		task.spawn(function()
			local count = 0
			for _, obj in ipairs(Services.Workspace:GetDescendants()) do
				if obj:IsA("BasePart") then
					if not Cache.Materials[obj] then Cache.Materials[obj] = obj.Material end
					obj.Material = Enum.Material.SmoothPlastic
				end
				count += 1
				if count % 250 == 0 then task.wait() end
			end
		end)
	else
		for obj, mat in pairs(Cache.Materials) do
			if obj and obj.Parent then obj.Material = mat end
		end
	end
end)

createToggle("Deactivate Humanoid States", 6, function(state)
	OptStates.DeactivateAnims = state
	if state then
		for _, obj in ipairs(Services.Workspace:GetDescendants()) do
			if obj:IsA("Animator") and Hub.HookAnimator then Hub.HookAnimator(obj) end
		end
	else
		for _, obj in ipairs(Services.Workspace:GetDescendants()) do
			if obj:IsA("Animator") then
				for _, track in ipairs(obj:GetPlayingAnimationTracks()) do track:AdjustSpeed(1) end
			end
		end
	end
end)

createToggle("UI Visibility Toggle", 7, function(state)
	OptStates.HideUIs = state
	if state then
		for _, gui in ipairs(PlayerGui:GetChildren()) do
			if Hub.MonitorGui then Hub.MonitorGui(gui) end
		end
	else
		for gui, enabledState in pairs(Cache.UIs) do
			if gui and gui.Parent then gui.Enabled = enabledState end
		end
	end
end)

createToggle("Shadow Killer", 8, function(state)
	OptStates.ShadowKiller = state
	Lighting.GlobalShadows = not state
	task.spawn(function()
		local count = 0
		for _, obj in ipairs(Services.Workspace:GetDescendants()) do
			if obj:IsA("BasePart") then obj.CastShadow = not state end
			count += 1
			if count % 250 == 0 then task.wait() end
		end
	end)
end)

createToggle("Pause 3D rendering", 9, function(state)
	OptStates.PauseRenderQuality = state
	pcall(function()
		settings().Rendering.QualityLevel = state and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic
	end)
end)

createToggle("Memory Cleaner", 10, function(state)
	OptStates.MemoryCleaner = state
	if state then
		Cache.Connections["MM2CleanerActive"] = true

		local function performFullCleanup()
			task.spawn(function()
				local count = 0
				for _, obj in ipairs(Services.Workspace:GetDescendants()) do
					if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Sparkles") or obj:IsA("Smoke") or obj:IsA("Fire") then
						obj.Enabled = false
					elseif obj:IsA("Sound") and not obj.IsPlaying and obj.Parent ~= LocalPlayer then
						pcall(function() obj:Destroy() end)
					end
					count += 1
					if count % 250 == 0 then task.wait() end
				end

				for _, player in ipairs(Players:GetPlayers()) do
					if player ~= LocalPlayer and player.Character then
						local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
						if humanoid then
							local animator = humanoid:FindFirstChildOfClass("Animator")
							if animator then
								for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
									track:Stop(0)
								end
							end
						end
					end
				end
				pcall(function() collectgarbage("count") end)
			end)
		end

		performFullCleanup()
		task.spawn(function()
			while Cache.Connections["MM2CleanerActive"] do
				task.wait(300)
				if Cache.Connections["MM2CleanerActive"] then performFullCleanup() end
			end
		end)
	else
		Cache.Connections["MM2CleanerActive"] = false
	end
end)

-----------------------------------
-- CONFIG TAB BUILDER
-----------------------------------
local configView = tabFrames["Config"].View

local createConfigSection = createDropdownSection(configView, "CREATE CONFIG", 1)

local configNameInput = Instance.new("TextBox")
configNameInput.Size = UDim2.new(1, -20, 0, 32)
configNameInput.Position = UDim2.new(0, 10, 0, 0)
configNameInput.BackgroundColor3 = Theme.TabBackground
configNameInput.PlaceholderText = "Enter Config Name"
configNameInput.Text = ""
configNameInput.TextColor3 = Theme.TextActive
configNameInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
configNameInput.Font = Enum.Font.GothamMedium
configNameInput.TextSize = 13
configNameInput.LayoutOrder = 1
configNameInput.Parent = createConfigSection
Instance.new("UICorner", configNameInput).CornerRadius = UDim.new(0, 6)

local nameInputStroke = Instance.new("UIStroke")
nameInputStroke.Color = Theme.Border
nameInputStroke.Thickness = 1
nameInputStroke.Parent = configNameInput

local saveConfigBtn = Instance.new("TextButton")
saveConfigBtn.Size = UDim2.new(1, -20, 0, 32)
saveConfigBtn.Position = UDim2.new(0, 10, 0, 0)
saveConfigBtn.BackgroundColor3 = Theme.ToggleOn_Bg
saveConfigBtn.Text = "Save Config"
saveConfigBtn.TextColor3 = Theme.ToggleOn_Text
saveConfigBtn.Font = Enum.Font.GothamMedium
saveConfigBtn.TextSize = 13
saveConfigBtn.LayoutOrder = 2
saveConfigBtn.Parent = createConfigSection
Instance.new("UICorner", saveConfigBtn).CornerRadius = UDim.new(0, 6)

local saveBtnStroke = Instance.new("UIStroke")
saveBtnStroke.Color = Theme.ToggleOn_Stroke
saveBtnStroke.Thickness = 1
saveBtnStroke.Parent = saveConfigBtn

saveConfigBtn.MouseButton1Click:Connect(function()
	local name = configNameInput.Text:gsub("[^%w_%-]", "")
	if name == "" then
		saveConfigBtn.Text = "Invalid Name!"
		task.delay(1.5, function() saveConfigBtn.Text = "Save Config" end)
		return
	end

	local configData = Hub.GetSerializedConfig and Hub.GetSerializedConfig() or {}
	local rawJson = HttpService:JSONEncode(configData)

	if writefile then
		local success, err = pcall(function()
			writefile("Dashboard_Config_" .. name .. ".json", rawJson)
			if Hub.SaveConfigToManifest then Hub.SaveConfigToManifest(name) end
		end)
		if success then
			saveConfigBtn.Text = "Saved Config!"
			configNameInput.Text = ""
			task.delay(1.5, function() saveConfigBtn.Text = "Save Config" end)
			if populateConfigsDropdown then populateConfigsDropdown() end
		else
			saveConfigBtn.Text = "Save Error!"
			task.delay(1.5, function() saveConfigBtn.Text = "Save Config" end)
		end
	else
		saveConfigBtn.Text = "writefile not supported!"
		task.delay(2, function() saveConfigBtn.Text = "Save Config" end)
	end
end)

local shareConfigBtn = Instance.new("TextButton")
shareConfigBtn.Size = UDim2.new(1, -20, 0, 32)
shareConfigBtn.Position = UDim2.new(0, 10, 0, 0)
shareConfigBtn.BackgroundColor3 = Theme.TabBackground
shareConfigBtn.Text = "Generate & Copy Share Code"
shareConfigBtn.TextColor3 = Theme.TextActive
shareConfigBtn.Font = Enum.Font.GothamMedium
shareConfigBtn.TextSize = 13
shareConfigBtn.LayoutOrder = 3
shareConfigBtn.Parent = createConfigSection
Instance.new("UICorner", shareConfigBtn).CornerRadius = UDim.new(0, 6)

local shareBtnStroke = Instance.new("UIStroke")
shareBtnStroke.Color = Theme.Border
shareBtnStroke.Thickness = 1
shareBtnStroke.Parent = shareConfigBtn

shareConfigBtn.MouseButton1Click:Connect(function()
	local configData = Hub.GetSerializedConfig and Hub.GetSerializedConfig() or {}
	local rawJson = HttpService:JSONEncode(configData)
	local success, shareCode = pcall(function()
		return Hub.Base64Encode(rawJson)
	end)

	if success and shareCode then
		local setClip = setclipboard or (syn and syn.write_clipboard) or toclipboard
		if setClip then
			setClip(shareCode)
			shareConfigBtn.Text = "Share Code Copied!"
			task.delay(2, function() shareConfigBtn.Text = "Generate & Copy Share Code" end)
		else
			print("Config Share Code:\n" .. shareCode)
			shareConfigBtn.Text = "Copied to F9 Console!"
			task.delay(2, function() shareConfigBtn.Text = "Generate & Copy Share Code" end)
		end
	else
		shareConfigBtn.Text = "Encoding Error!"
		task.delay(2, function() shareConfigBtn.Text = "Generate & Copy Share Code" end)
	end
end)

local loadConfigSection = createDropdownSection(configView, "LOAD CONFIG", 2)
local selectedSavedConfig = nil

local selectConfigBtn = Instance.new("TextButton")
selectConfigBtn.Size = UDim2.new(1, -20, 0, 32)
selectConfigBtn.Position = UDim2.new(0, 10, 0, 0)
selectConfigBtn.BackgroundColor3 = Theme.TabBackground
selectConfigBtn.Text = "Select Saved Config  ▼"
selectConfigBtn.TextColor3 = Theme.TextActive
selectConfigBtn.Font = Enum.Font.GothamMedium
selectConfigBtn.TextSize = 13
selectConfigBtn.LayoutOrder = 1
selectConfigBtn.Parent = loadConfigSection
Instance.new("UICorner", selectConfigBtn).CornerRadius = UDim.new(0, 6)

local savedConfigsContainer = Instance.new("Frame")
savedConfigsContainer.Size = UDim2.new(1, -20, 0, 0)
savedConfigsContainer.Position = UDim2.new(0, 10, 0, 0)
savedConfigsContainer.BackgroundTransparency = 1
savedConfigsContainer.Visible = false
savedConfigsContainer.LayoutOrder = 2
savedConfigsContainer.Parent = loadConfigSection

local savedConfigsLayout = Instance.new("UIListLayout")
savedConfigsLayout.SortOrder = Enum.SortOrder.LayoutOrder
savedConfigsLayout.Padding = UDim.new(0, 4)
savedConfigsLayout.Parent = savedConfigsContainer

savedConfigsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	savedConfigsContainer.Size = UDim2.new(1, -20, 0, savedConfigsLayout.AbsoluteContentSize.Y)
end)

local selectDropdownOpen = false
selectConfigBtn.MouseButton1Click:Connect(function()
	selectDropdownOpen = not selectDropdownOpen
	savedConfigsContainer.Visible = selectDropdownOpen
	selectConfigBtn.Text = selectDropdownOpen and "Select Saved Config  ▲" or "Select Saved Config  ▼"
end)

function populateConfigsDropdown()
	for _, child in ipairs(savedConfigsContainer:GetChildren()) do
		if not child:IsA("UIListLayout") then child:Destroy() end
	end

	local manifest = Hub.GetConfigsManifest and Hub.GetConfigsManifest() or {}
	if #manifest == 0 then
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 0, 28)
		lbl.BackgroundTransparency = 1
		lbl.Text = "No saved configs found"
		lbl.TextColor3 = Theme.TextNormal
		lbl.Font = Enum.Font.GothamMedium
		lbl.TextSize = 12
		lbl.Parent = savedConfigsContainer
		return
	end

	for i, configName in ipairs(manifest) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 28)
		btn.BackgroundColor3 = Theme.ToggleOff_Bg
		btn.Text = configName
		btn.TextColor3 = Theme.TextNormal
		btn.Font = Enum.Font.GothamMedium
		btn.TextSize = 12
		btn.LayoutOrder = i
		btn.Parent = savedConfigsContainer
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

		btn.MouseButton1Click:Connect(function()
			selectedSavedConfig = configName
			selectConfigBtn.Text = "Selected: " .. configName
			selectDropdownOpen = false
			savedConfigsContainer.Visible = false
		end)
	end
end

populateConfigsDropdown()

local loadFileBtn = Instance.new("TextButton")
loadFileBtn.Size = UDim2.new(1, -20, 0, 32)
loadFileBtn.Position = UDim2.new(0, 10, 0, 0)
loadFileBtn.BackgroundColor3 = Theme.ToggleOn_Bg
loadFileBtn.Text = "Load Selected Config"
loadFileBtn.TextColor3 = Theme.ToggleOn_Text
loadFileBtn.Font = Enum.Font.GothamMedium
loadFileBtn.TextSize = 13
loadFileBtn.LayoutOrder = 3
loadFileBtn.Parent = loadConfigSection
Instance.new("UICorner", loadFileBtn).CornerRadius = UDim.new(0, 6)

loadFileBtn.MouseButton1Click:Connect(function()
	if not selectedSavedConfig then
		loadFileBtn.Text = "Select a Config First!"
		task.delay(1.5, function() loadFileBtn.Text = "Load Selected Config" end)
		return
	end

	if readfile and isfile and isfile("Dashboard_Config_" .. selectedSavedConfig .. ".json") then
		local success, content = pcall(function()
			return readfile("Dashboard_Config_" .. selectedSavedConfig .. ".json")
		end)
		if success and content then
			local dataSuccess, parsed = pcall(function()
				return HttpService:JSONDecode(content)
			end)
			if dataSuccess and parsed then
				if Hub.LoadConfigFromTable then Hub.LoadConfigFromTable(parsed) end
				loadFileBtn.Text = "Config Loaded!"
				task.delay(1.5, function() loadFileBtn.Text = "Load Selected Config" end)
			else
				loadFileBtn.Text = "File Parse Error!"
				task.delay(1.5, function() loadFileBtn.Text = "Load Selected Config" end)
			end
		else
			loadFileBtn.Text = "Read Error!"
			task.delay(1.5, function() loadFileBtn.Text = "Load Selected Config" end)
		end
	else
		loadFileBtn.Text = "File missing!"
		task.delay(1.5, function() loadFileBtn.Text = "Load Selected Config" end)
	end
end)

local shareCodeInput = Instance.new("TextBox")
shareCodeInput.Size = UDim2.new(1, -20, 0, 32)
shareCodeInput.Position = UDim2.new(0, 10, 0, 0)
shareCodeInput.BackgroundColor3 = Theme.TabBackground
shareCodeInput.PlaceholderText = "Paste Share Code here"
shareCodeInput.Text = ""
shareCodeInput.TextColor3 = Theme.TextActive
shareCodeInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
shareCodeInput.Font = Enum.Font.GothamMedium
shareCodeInput.TextSize = 13
shareCodeInput.LayoutOrder = 4
shareCodeInput.Parent = loadConfigSection
Instance.new("UICorner", shareCodeInput).CornerRadius = UDim.new(0, 6)

local loadShareConfigBtn = Instance.new("TextButton")
loadShareConfigBtn.Size = UDim2.new(1, -20, 0, 32)
loadShareConfigBtn.Position = UDim2.new(0, 10, 0, 0)
loadShareConfigBtn.BackgroundColor3 = Theme.ToggleOn_Bg
loadShareConfigBtn.Text = "Load Share Config"
loadShareConfigBtn.TextColor3 = Theme.ToggleOn_Text
loadShareConfigBtn.Font = Enum.Font.GothamMedium
loadShareConfigBtn.TextSize = 13
loadShareConfigBtn.LayoutOrder = 5
loadShareConfigBtn.Parent = loadConfigSection
Instance.new("UICorner", loadShareConfigBtn).CornerRadius = UDim.new(0, 6)

loadShareConfigBtn.MouseButton1Click:Connect(function()
	local code = shareCodeInput.Text
	if code == "" then return end

	local decodedSuccess, decoded = pcall(function()
		return Hub.Base64Decode(code)
	end)
	if decodedSuccess and decoded then
		local dataSuccess, parsed = pcall(function()
			return HttpService:JSONDecode(decoded)
		end)
		if dataSuccess and parsed then
			if Hub.LoadConfigFromTable then Hub.LoadConfigFromTable(parsed) end
			loadShareConfigBtn.Text = "Share Config Loaded!"
			shareCodeInput.Text = ""
			task.delay(1.5, function() loadShareConfigBtn.Text = "Load Share Config" end)
		else
			loadShareConfigBtn.Text = "Invalid Config Data!"
			task.delay(1.5, function() loadShareConfigBtn.Text = "Load Share Config" end)
		end
	else
		loadShareConfigBtn.Text = "Failed to Decode Code!"
		task.delay(1.5, function() loadShareConfigBtn.Text = "Load Share Config" end)
	end
end)

-----------------------------------
-- SETTINGS TAB BUILDER
-----------------------------------
local settingsView = tabFrames["Settings"].View

local function createSettingsButton(text, layoutOrder, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -15, 0, 32)
	btn.BackgroundColor3 = Theme.TabBackground
	btn.Text = text
	btn.TextColor3 = Theme.TextActive
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 14
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.LayoutOrder = layoutOrder
	btn.Parent = settingsView
	
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 15)
	padding.Parent = btn
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Border
	stroke.Thickness = 1
	stroke.Parent = btn
	
	btn.MouseButton1Click:Connect(function() callback(btn) end)
	return btn
end

local function createSettingsToggle(text, layoutOrder, defaultState, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -15, 0, 32)
	btn.BackgroundColor3 = defaultState and Theme.ToggleOn_Bg or Theme.ToggleOff_Bg
	btn.Text = text
	btn.TextColor3 = defaultState and Theme.ToggleOn_Text or Theme.ToggleOff_Text
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 14
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.LayoutOrder = layoutOrder
	btn.Parent = settingsView
	
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 15)
	padding.Parent = btn
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.ToggleOn_Stroke
	stroke.Thickness = 1.5
	stroke.Transparency = defaultState and 0 or 1
	stroke.Parent = btn
	
	local isOn = defaultState
	local function setToggle(state)
		isOn = state
		btn.BackgroundColor3 = isOn and Theme.ToggleOn_Bg or Theme.ToggleOff_Bg
		btn.TextColor3 = isOn and Theme.ToggleOn_Text or Theme.ToggleOff_Text
		stroke.Transparency = isOn and 0 or 1
		callback(isOn, btn)
	end

	btn.MouseButton1Click:Connect(function() setToggle(not isOn) end)
	if defaultState then task.defer(function() callback(true, btn) end) end

	UIControls.Toggles[text] = setToggle
	return btn
end

createSettingsButton("Rejoin Server", 1, function(btn)
	btn.Text = "Rejoining Server..."
	TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

createSettingsButton("Server Hop (Join Random Server)", 2, function(btn)
	if Hub.JoinRandomServer then Hub.JoinRandomServer(btn) end
end)

createSettingsButton("Copy Join Code", 3, function(btn)
	local joinScript = string.format("game:GetService('TeleportService'):TeleportToPlaceInstance(%d, '%s', game:GetService('Players').LocalPlayer)", game.PlaceId, game.JobId)
	
	local setClip = setclipboard or (syn and syn.write_clipboard) or toclipboard
	if setClip then
		setClip(joinScript)
		btn.Text = "Copied to Clipboard!"
		task.delay(2, function() btn.Text = "Copy Join Code" end)
	else
		btn.Text = "Clipboard API not supported!"
		task.delay(2, function() btn.Text = "Copy Join Code" end)
	end
end)

local autoRejoinState = false
pcall(function()
	if readfile and isfile and isfile("Dashboard_AutoRejoin.txt") then
		autoRejoinState = (readfile("Dashboard_AutoRejoin.txt") == "true")
	end
end)

createSettingsToggle("Auto Rejoin (45 Min Loop)", 4, autoRejoinState, function(state, btn)
	if Hub.SetAutoRejoin then Hub.SetAutoRejoin(state) end
end)

print("[MM2 Hub] UIFramework.lua loaded successfully!")
