--!nocheck
-----------------------------------
-- CORE STATE & UTILITIES MODULE
-----------------------------------
getgenv().Hub = getgenv().Hub or {}
local Hub = getgenv().Hub

-- Services
Hub.Services = {
	Players = game:GetService("Players"),
	RunService = game:GetService("RunService"),
	UserInputService = game:GetService("UserInputService"),
	Workspace = game:GetService("Workspace"),
	Lighting = game:GetService("Lighting"),
	TeleportService = game:GetService("TeleportService"),
	TweenService = game:GetService("TweenService"),
	SoundService = game:GetService("SoundService"),
	HttpService = game:GetService("HttpService")
}

local Players = Hub.Services.Players
local RunService = Hub.Services.RunService
local Workspace = Hub.Services.Workspace
local TeleportService = Hub.Services.TeleportService
local HttpService = Hub.Services.HttpService

-- Environment Setup
Hub.LocalPlayer = Players.LocalPlayer
Hub.PlayerGui = Hub.LocalPlayer:WaitForChild("PlayerGui")

-----------------------------------
-- GLOBAL OPTIMIZATION STATE MANAGER
-----------------------------------
Hub.OptStates = {
	AntiIdle = false,
	ThreeDRender = false,
	FPSLimit = 60,
	MuteAudio = false,
	SimplifyMaterials = false,
	DeactivateAnims = false,
	HideUIs = false,
	ShadowKiller = false,
	PauseRenderQuality = false,
	MemoryCleaner = false,
}

Hub.Cache = {
	Materials = setmetatable({}, {__mode = "k"}),
	Volumes = setmetatable({}, {__mode = "k"}),
	UIs = setmetatable({}, {__mode = "k"}),
	Connections = {},
	TweenSpeed = 20,
	YOffset = 2,
	Use5YOffset = true,
	CurrentTween = nil
}

Hub.CollectedCoins = {}
Hub.VisualSelectedBots = {}

Hub.SquadAllReadyTime = nil
Hub.KnownMurderer = nil
Hub.HasResetThisRound = false

Hub.Stats = {
	CoinsInBag = 0,
	CoinsLastRound = 0,
	TotalCoinsFarmed = 0,
	CurrentRole = "INNOCENT",
	MurdererName = "None",
	SheriffName = "None",
	InLobby = true,
	SquadReadyText = "1/1",
	AllReady = false,
	LastBagCount = 0
}

Hub.Theme = {
	Background = Color3.fromRGB(15, 15, 17),
	Header = Color3.fromRGB(22, 22, 25),
	Border = Color3.fromRGB(45, 45, 45),
	TabBackground = Color3.fromRGB(30, 30, 30),
	TextNormal = Color3.fromRGB(170, 170, 170),
	TextActive = Color3.fromRGB(255, 255, 255),
	ToggleOff_Bg = Color3.fromRGB(35, 35, 40),
	ToggleOff_Text = Color3.fromRGB(170, 170, 170),
	ToggleOn_Bg = Color3.fromRGB(65, 15, 20),         
	ToggleOn_Text = Color3.fromRGB(255, 130, 130),    
	ToggleOn_Stroke = Color3.fromRGB(200, 35, 45),    
	AccentRed = Color3.fromRGB(180, 30, 40),
	RoleRed = Color3.fromRGB(255, 75, 75),
	RoleBlue = Color3.fromRGB(75, 160, 255)
}

Hub.UIControls = {
	Toggles = {},
	Sliders = {}
}

-----------------------------------
-- FAST & BULLETPROOF BASE64 ENCODER/DECODER
-----------------------------------
local b64Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

function Hub.Base64Encode(data)
	if not data or #data == 0 then return "" end
	local bytes = {string.byte(data, 1, #data)}
	local len = #bytes
	local result = {}
	
	for i = 1, len, 3 do
		local b1 = bytes[i]
		local b2 = bytes[i + 1]
		local b3 = bytes[i + 2]
		
		local n = bit32.lshift(b1, 16) + bit32.lshift(b2 or 0, 8) + (b3 or 0)
		
		local c1 = bit32.extract(n, 18, 6)
		local c2 = bit32.extract(n, 12, 6)
		local c3 = b2 and bit32.extract(n, 6, 6) or 64
		local c4 = b3 and bit32.extract(n, 0, 6) or 64
		
		table.insert(result, b64Chars:sub(c1 + 1, c1 + 1))
		table.insert(result, b64Chars:sub(c2 + 1, c2 + 1))
		table.insert(result, c3 == 64 and "=" or b64Chars:sub(c3 + 1, c3 + 1))
		table.insert(result, c4 == 64 and "=" or b64Chars:sub(c4 + 1, c4 + 1))
	end
	
	return table.concat(result)
end

function Hub.Base64Decode(data)
	data = string.gsub(data, '[^' .. b64Chars .. '=]', '')
	if not data or #data == 0 then return "" end
	
	local result = {}
	for i = 1, #data, 4 do
		local char1 = data:sub(i, i)
		local char2 = data:sub(i + 1, i + 1)
		local char3 = data:sub(i + 2, i + 2)
		local char4 = data:sub(i + 3, i + 3)
		
		local c1 = b64Chars:find(char1, 1, true)
		local c2 = b64Chars:find(char2, 1, true)
		local c3 = b64Chars:find(char3, 1, true)
		local c4 = b64Chars:find(char4, 1, true)
		
		if c1 and c2 then
			local n = bit32.lshift(c1 - 1, 18) + bit32.lshift(c2 - 1, 12) 
				+ bit32.lshift((c3 and c3 <= 64) and (c3 - 1) or 0, 6) 
				+ ((c4 and c4 <= 64) and (c4 - 1) or 0)
			
			table.insert(result, string.char(bit32.extract(n, 16, 8)))
			if c3 and c3 <= 64 and char3 ~= "=" then
				table.insert(result, string.char(bit32.extract(n, 8, 8)))
			end
			if c4 and c4 <= 64 and char4 ~= "=" then
				table.insert(result, string.char(bit32.extract(n, 0, 8)))
			end
		end
	end
	
	return table.concat(result)
end

-----------------------------------
-- REAL-TIME KNIFE MONITOR
-----------------------------------
RunService.Heartbeat:Connect(function()
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char then
			for _, item in ipairs(char:GetChildren()) do
				if item:IsA("Tool") then
					local name = item.Name:lower()
					if name:find("knife") or item:FindFirstChild("KnifeServer") or item:FindFirstChild("Stab") or item:FindFirstChild("LockOn") then
						Hub.KnownMurderer = player
					end
				end
			end
		end
	end
end)

-----------------------------------
-- ACCURATE ROLE DETECTION SYSTEM
-----------------------------------
function Hub.GetLocalPlayerRole()
	local char = Hub.LocalPlayer.Character
	local backpack = Hub.LocalPlayer:FindFirstChild("Backpack")

	local function checkContainer(container)
		if not container then return nil end
		for _, item in ipairs(container:GetChildren()) do
			if item:IsA("Tool") then
				local name = item.Name:lower()
				if name == "knife" or item:FindFirstChild("KnifeServer") or item:FindFirstChild("Stab") then
					return "MURDERER"
				end
				if name == "gun" or item:FindFirstChild("GunServer") or item:FindFirstChild("ShootGun") then
					return "SHERIFF"
				end
			end
		end
		return nil
	end

	local roleFromTool = checkContainer(char) or checkContainer(backpack)
	if roleFromTool then return roleFromTool end

	local mainGui = Hub.PlayerGui:FindFirstChild("MainGUI") or Hub.PlayerGui:FindFirstChild("MainGui")
	if mainGui then
		local gameFrame = mainGui:FindFirstChild("Game") or mainGui:FindFirstChild("GameFrame")
		if gameFrame then
			local roleObj = gameFrame:FindFirstChild("Role")
			if roleObj and (roleObj:IsA("TextLabel") or roleObj:IsA("TextButton")) and roleObj.Visible then
				local text = string.upper(tostring(roleObj.Text or roleObj.ContentText or ""))
				if text:find("MURDERER") then return "MURDERER" end
				if text:find("SHERIFF") or text:find("HERO") then return "SHERIFF" end
				if text:find("INNOCENT") then return "INNOCENT" end
			end
		end
	end

	return "INNOCENT"
end

function Hub.IsMurderer(player)
	player = player or Hub.LocalPlayer
	if player == Hub.LocalPlayer then return Hub.GetLocalPlayerRole() == "MURDERER" end
	local char = player and player.Character
	if char then
		for _, tool in ipairs(char:GetChildren()) do
			if tool:IsA("Tool") then
				local name = tool.Name:lower()
				if name == "knife" or tool:FindFirstChild("KnifeServer") or tool:FindFirstChild("Stab") then return true end
			end
		end
	end
	return false
end

function Hub.IsSheriff(player)
	player = player or Hub.LocalPlayer
	if player == Hub.LocalPlayer then return Hub.GetLocalPlayerRole() == "SHERIFF" end
	local char = player and player.Character
	if char then
		for _, tool in ipairs(char:GetChildren()) do
			if tool:IsA("Tool") then
				local name = tool.Name:lower()
				if name == "gun" or tool:FindFirstChild("GunServer") or tool:FindFirstChild("ShootGun") then return true end
			end
		end
	end
	return false
end

-----------------------------------
-- MM2 BAG & LOBBY HELPERS
-----------------------------------
function Hub.GetLobbyCFrame()
	local lobby = Workspace:FindFirstChild("Lobby") or Workspace:FindFirstChild("LobbyModel")
	if lobby then
		local basePart = lobby:FindFirstChildWhichIsA("BasePart", true)
		if basePart then return basePart.CFrame + Vector3.new(0, 4, 0) end
		if lobby:IsA("Model") then return lobby:GetPivot() + Vector3.new(0, 4, 0) end
	end
	local spawns = Workspace:FindFirstChild("Spawns") or Workspace:FindFirstChild("SpawnLocation", true)
	if spawns then
		if spawns:IsA("Folder") or spawns:IsA("Model") then
			local p = spawns:FindFirstChildWhichIsA("BasePart", true)
			if p then return p.CFrame + Vector3.new(0, 4, 0) end
			return spawns:GetPivot() + Vector3.new(0, 4, 0)
		elseif spawns:IsA("BasePart") then
			return spawns.CFrame + Vector3.new(0, 4, 0)
		end
	end
	return CFrame.new(0, 100, 0)
end

function Hub.IsPlayerInLobby(hrp)
	if not hrp then return true end
	local lobbyCF = Hub.GetLobbyCFrame()
	local dist = (hrp.Position - lobbyCF.Position).Magnitude
	return dist < 250
end

function Hub.GetCurrentCoinCount()
	local mainGui = Hub.PlayerGui:FindFirstChild("MainGUI") or Hub.PlayerGui:FindFirstChild("MainGui")
	if not mainGui then return 0 end
	local coinsObj = nil
	pcall(function() coinsObj = mainGui.Game.CoinBags.Container.Coin.CurrencyFrame.Icon.Coins end)
	if not coinsObj then
		local coinBags = mainGui:FindFirstChild("CoinBags", true)
		if coinBags then coinsObj = coinBags:FindFirstChild("Coins", true) end
	end
	if coinsObj and (coinsObj:IsA("TextLabel") or coinsObj:IsA("TextButton")) then
		local text = tostring(coinsObj.Text or coinsObj.ContentText or "")
		local num = tonumber(text:match("(%d+)"))
		if num then return num end
	end
	return 0
end

function Hub.IsBagFull()
	local count = Hub.GetCurrentCoinCount()
	return count >= 40
end

function Hub.GetPublicMurderer()
	if Hub.KnownMurderer and Hub.KnownMurderer.Parent and Hub.KnownMurderer.Character then
		local hum = Hub.KnownMurderer.Character:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then return Hub.KnownMurderer end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= Hub.LocalPlayer and not Hub.VisualSelectedBots[player.UserId] then
			if Hub.IsMurderer(player) then
				Hub.KnownMurderer = player
				return player
			end
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= Hub.LocalPlayer and not Hub.VisualSelectedBots[player.UserId] then
			local pChar = player.Character
			local pHum = pChar and pChar:FindFirstChildOfClass("Humanoid")
			local pHrp = pChar and pChar:FindFirstChild("HumanoidRootPart")
			if pChar and pHum and pHum.Health > 0 and pHrp and not Hub.IsPlayerInLobby(pHrp) then
				return player
			end
		end
	end

	return nil
end

function Hub.GetPublicSheriff()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= Hub.LocalPlayer and not Hub.VisualSelectedBots[player.UserId] then
			if Hub.IsSheriff(player) then return player end
		end
	end
	return nil
end

function Hub.IsBotReady(botPlayer)
	if not botPlayer then return true end
	local char = botPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")

	if not char or not hum or hum.Health <= 0 or not hrp or Hub.IsPlayerInLobby(hrp) then
		return true
	end
	return false
end

function Hub.SetNoclip(enabled)
	if enabled then
		if not Hub.Cache.Connections["Noclip"] then
			Hub.Cache.Connections["Noclip"] = RunService.Stepped:Connect(function()
				local char = Hub.LocalPlayer.Character
				if char then
					for _, part in ipairs(char:GetDescendants()) do
						if part:IsA("BasePart") then part.CanCollide = false end
					end
				end
			end)
		end
	else
		if Hub.Cache.Connections["Noclip"] then
			Hub.Cache.Connections["Noclip"]:Disconnect()
			Hub.Cache.Connections["Noclip"] = nil
		end
		local char = Hub.LocalPlayer.Character
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = true end
			end
		end
	end
end

function Hub.GetAlivePlayers()
	local inTotal = {}
	local inMap = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local char = p.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if char and hum and hum.Health > 0 then
			table.insert(inTotal, p)
			if hrp and not Hub.IsPlayerInLobby(hrp) then table.insert(inMap, p) end
		end
	end
	return inTotal, inMap
end

function Hub.JoinRandomServer(btn)
	if btn then btn.Text = "Finding Random Server..." end
	local placeId = game.PlaceId
	local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

	if req then
		task.spawn(function()
			local success, result = pcall(function()
				local res = req({
					Url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100", placeId),
					Method = "GET"
				})
				return HttpService:JSONDecode(res.Body)
			end)

			if success and result and result.data then
				local validServers = {}
				for _, server in ipairs(result.data) do
					if type(server) == "table" and server.id ~= game.JobId and server.playing and server.maxPlayers and server.playing < server.maxPlayers then
						table.insert(validServers, server.id)
					end
				end

				if #validServers > 0 then
					local randomServerId = validServers[math.random(1, #validServers)]
					if btn then btn.Text = "Teleporting..." end
					TeleportService:TeleportToPlaceInstance(placeId, randomServerId, Hub.LocalPlayer)
					return
				end
			end

			if btn then btn.Text = "Teleporting to Random Server..." end
			TeleportService:Teleport(placeId, Hub.LocalPlayer)
		end)
	else
		if btn then btn.Text = "Teleporting to Random Server..." end
		TeleportService:Teleport(placeId, Hub.LocalPlayer)
	end
end

function Hub.GetCoins()
	local coins = {}
	local container = Workspace:FindFirstChild("CoinContainer", true) or Workspace:FindFirstChild("Coin_Container", true)
	if container then
		for _, coin in ipairs(container:GetChildren()) do
			if not Hub.CollectedCoins[coin] then
				if coin:IsA("BasePart") then table.insert(coins, coin)
				elseif coin:IsA("Model") then
					local p = coin.PrimaryPart or coin:FindFirstChildWhichIsA("BasePart")
					if p then table.insert(coins, p) end
				end
			end
		end
	else
		for _, descendant in ipairs(Workspace:GetChildren()) do
			if descendant.Name == "Coin_Server" or (descendant:IsA("BasePart") and descendant.Name:lower():find("coin")) then
				if not descendant:IsDescendantOf(Hub.LocalPlayer.Character) and descendant:IsA("BasePart") then
					if not Hub.CollectedCoins[descendant] then table.insert(coins, descendant) end
				end
			end
		end
	end

	if #coins > 0 then
		Hub.SquadAllReadyTime = nil
		Hub.KnownMurderer = nil
		Hub.HasResetThisRound = false
	end

	return coins
end

-- Respawn Listener
Hub.LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(0.2)
	if Hub.Cache.Connections["Noclip"] then
		Hub.SetNoclip(true)
	end
	Hub.HasResetThisRound = false
	Hub.SquadAllReadyTime = nil
end)

print("[MM2 Hub] CoreState.lua loaded successfully!")
