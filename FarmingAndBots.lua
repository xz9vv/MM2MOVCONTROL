--!nocheck
-----------------------------------
-- FARMING & BOT SYNC MODULE
-----------------------------------
local Hub = getgenv().Hub
if not Hub then
	warn("[MM2 Hub] CoreState.lua must be loaded before FarmingAndBots.lua!")
	return
end

local Services = Hub.Services
local Players = Services.Players
local RunService = Services.RunService
local TweenService = Services.TweenService
local Workspace = Services.Workspace

local LocalPlayer = Hub.LocalPlayer
local Cache = Hub.Cache
local Stats = Hub.Stats
local CollectedCoins = Hub.CollectedCoins
local VisualSelectedBots = Hub.VisualSelectedBots

-----------------------------------
-- LOCAL BLACK FARM PLATFORM SYSTEM
-----------------------------------
local farmPlatform = nil

local function createFarmPlatform()
	if farmPlatform and farmPlatform.Parent then 
		return farmPlatform 
	end

	local part = Instance.new("Part")
	part.Name = "LocalFarmPlatform"
	part.Size = Vector3.new(8, 1, 8)
	part.Color = Color3.fromRGB(0, 0, 0)
	part.Material = Enum.Material.SmoothPlastic
	part.Transparency = 0
	part.CanCollide = true
	part.Anchored = true
	part.CastShadow = false
	part.Parent = Workspace

	farmPlatform = part
	return part
end

local function destroyFarmPlatform()
	if farmPlatform then
		pcall(function() farmPlatform:Destroy() end)
		farmPlatform = nil
	end
end

-----------------------------------
-- FOOLPROOF MURDERER DETECTOR
-----------------------------------
local function IsMurdererWeapon(tool)
	if not tool or not tool:IsA("Tool") then return false end
	local nameLower = tool.Name:lower()
	
	if nameLower:find("knife") or nameLower:find("blade") or nameLower:find("dagger") or nameLower == "bat" then
		return true
	end

	if tool:FindFirstChild("KnifeServer") or tool:FindFirstChild("KnifeClient") or tool:FindFirstChild("LockOn") then
		return true
	end

	return false
end

local function GetPublicMurdererFoolproof()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			local equipped = player.Character:FindFirstChildOfClass("Tool")
			if equipped and IsMurdererWeapon(equipped) then
				return player
			end
			local backpack = player:FindFirstChild("Backpack")
			if backpack then
				for _, item in ipairs(backpack:GetChildren()) do
					if IsMurdererWeapon(item) then
						return player
					end
				end
			end
		end
	end
	return nil
end

Hub.GetPublicMurderer = GetPublicMurdererFoolproof

-----------------------------------
-- HARDCODED SHERIFF SHOOTER
-----------------------------------
local isShootingLoopActive = false
local function shootMurdererLooped(murdPlayer)
	if isShootingLoopActive or not murdPlayer then return end
	isShootingLoopActive = true

	task.spawn(function()
		while Cache.Connections["BotSyncActive"] do
			local char = LocalPlayer.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			
			local murdChar = murdPlayer and murdPlayer.Character
			local murdHRP = murdChar and murdChar:FindFirstChild("HumanoidRootPart")
			local murdHum = murdChar and murdChar:FindFirstChildOfClass("Humanoid")

			if not hrp or not murdHRP or not hum or hum.Health <= 0 or not murdHum or murdHum.Health <= 0 then 
				break 
			end

			if murdHRP.Position.Y < -20 then
				break
			end

			local totalAlive, _ = Hub.GetAlivePlayers()
			if #totalAlive <= 2 and table.find(totalAlive, LocalPlayer) and table.find(totalAlive, murdPlayer) then
				print("[BOT SYNC] Safeguard Triggered: Only Sheriff & Murderer alive. Resetting!")
				hum.Health = 0
				break
			end

			local gun = char:FindFirstChild("Gun") or char:FindFirstChildWhichIsA("Tool")
			if not gun or not (gun.Name:lower():find("gun") or gun.Name:lower():find("revolver")) then
				if LocalPlayer:FindFirstChild("Backpack") then
					gun = LocalPlayer.Backpack:FindFirstChild("Gun") or LocalPlayer.Backpack:FindFirstChildWhichIsA("Tool")
				end
			end

			if gun then
				gun.Parent = char
				Hub.SetNoclip(true)

				local murdLook = murdHRP.CFrame.LookVector
				local targetPos = murdHRP.Position - (murdLook * 3) + Vector3.new(0, 1, 0)
				local targetCFrame = CFrame.lookAt(targetPos, murdHRP.Position)

				local dist = (hrp.Position - targetPos).Magnitude
				local duration = math.clamp(dist / (Cache.TweenSpeed or 25), 0.05, 0.2)
				local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
				local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
				tween:Play()

				pcall(function()
					gun:Activate()
					
					local shootRemote = gun:FindFirstChild("Shoot", true)
					if shootRemote and shootRemote:IsA("RemoteEvent") then
						pcall(function() shootRemote:FireServer(murdHRP.Position, murdHRP.Position, murdHRP, murdHRP.Position) end)
						pcall(function() shootRemote:FireServer(murdHRP.Position) end)
					end
				end)

				task.wait(duration + 0.05)
			else
				break
			end
		end
		isShootingLoopActive = false
	end)
end

Hub.ShootMurdererLooped = shootMurdererLooped

-----------------------------------
-- DOWNWARD VOID FLINGER
-----------------------------------
local isFlingingActive = false
local function flingMurdererLooped(murdPlayer)
	if isFlingingActive or not murdPlayer then return end
	isFlingingActive = true

	task.spawn(function()
		while Cache.Connections["BotSyncActive"] do
			local char = LocalPlayer.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")

			local murdChar = murdPlayer and murdPlayer.Character
			local murdHRP = murdChar and murdChar:FindFirstChild("HumanoidRootPart")
			local mHum = mHum or (murdChar and murdChar:FindFirstChildOfClass("Humanoid"))

			if not hrp or not murdHRP or not hum or hum.Health <= 0 or not mHum or mHum.Health <= 0 then
				break
			end

			if murdHRP.Position.Y < -20 then
				break
			end

			Hub.SetNoclip(true)

			hum.PlatformStand = true
			hrp.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
			
			hrp.AssemblyAngularVelocity = Vector3.new(0, 999999, 0)
			hrp.AssemblyLinearVelocity = Vector3.new(0, -2500, 0)

			hrp.CFrame = murdHRP.CFrame * CFrame.new(math.random(-0.5, 0.5), 2.5, math.random(-0.5, 0.5))

			RunService.Heartbeat:Wait()
		end

		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then hum.PlatformStand = false end
		if hrp then 
			hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0) 
			hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		end
		isFlingingActive = false
	end)
end

-----------------------------------
-- HELPER: DETERMINISTIC SQUAD RANK
-----------------------------------
local function GetSquadRank()
	local squad = { LocalPlayer }
	for userId, isSelected in pairs(VisualSelectedBots) do
		if isSelected then
			local botPlayer = Players:GetPlayerByUserId(userId)
			if botPlayer then
				table.insert(squad, botPlayer)
			end
		end
	end
	
	table.sort(squad, function(a, b)
		return a.UserId < b.UserId
	end)
	
	for idx, player in ipairs(squad) do
		if player == LocalPlayer then
			return idx, #squad
		end
	end
	return 1, 1
end

local function GetOtherSquadHRPs()
	local hrps = {}
	for userId, isSelected in pairs(VisualSelectedBots) do
		if isSelected then
			local botPlayer = Players:GetPlayerByUserId(userId)
			if botPlayer and botPlayer ~= LocalPlayer and botPlayer.Character then
				local bHRP = botPlayer.Character:FindFirstChild("HumanoidRootPart")
				if bHRP then
					table.insert(hrps, bHRP)
				end
			end
		end
	end
	return hrps
end

-- New Helper: Gets HRPs of other bots that are actively farming
local function GetActiveSquadHRPs()
	local hrps = {}
	for userId, isSelected in pairs(VisualSelectedBots) do
		if isSelected then
			local botPlayer = Players:GetPlayerByUserId(userId)
			if botPlayer and botPlayer ~= LocalPlayer and botPlayer.Character then
				local bHRP = botPlayer.Character:FindFirstChild("HumanoidRootPart")
				local bHum = botPlayer.Character:FindFirstChildOfClass("Humanoid")
				
				if bHRP and bHum and bHum.Health > 0 then
					local inLobby = Hub.IsPlayerInLobby(bHRP)
					local bagFull = botPlayer:GetAttribute("BagFull") == true
					
					-- Only count as active if they aren't in lobby or full
					if not inLobby and not bagFull then
						table.insert(hrps, bHRP)
					end
				end
			end
		end
	end
	return hrps
end

-----------------------------------
-- COIN FARM TOGGLE & LOOP
-----------------------------------
function Hub.StartCoinFarm(state)
	Cache.Connections["CoinFarmActive"] = state

	if not state then
		if Cache.CurrentTween then
			pcall(function() Cache.CurrentTween:Cancel() Cache.CurrentTween:Destroy() end)
			Cache.CurrentTween = nil
		end
		destroyFarmPlatform()
		Hub.SetNoclip(false)
		return
	end

	task.spawn(function()
		while Cache.Connections["CoinFarmActive"] do
			task.wait(0.01)

			local char = LocalPlayer.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")

			if not hrp or not hum or hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead then
				if Cache.CurrentTween then
					pcall(function() Cache.CurrentTween:Cancel() Cache.CurrentTween:Destroy() end)
					Cache.CurrentTween = nil
				end
				destroyFarmPlatform()
				Hub.SetNoclip(false)
				task.wait(0.5)
				continue
			end

			if Hub.IsPlayerInLobby(hrp) then
				if Cache.CurrentTween then
					pcall(function() Cache.CurrentTween:Cancel() Cache.CurrentTween:Destroy() end)
					Cache.CurrentTween = nil
				end
				destroyFarmPlatform()
				Hub.SetNoclip(false)
				task.wait(0.5)
				continue
			end

			Hub.WasOnMapThisRound = true

			local full = Hub.IsBagFull()
			LocalPlayer:SetAttribute("BagFull", full)
			
			if full then
				if Cache.CurrentTween then
					pcall(function() Cache.CurrentTween:Cancel() Cache.CurrentTween:Destroy() end)
					Cache.CurrentTween = nil
				end
				destroyFarmPlatform()
				Hub.SetNoclip(false)

				hrp.CFrame = Hub.GetLobbyCFrame()

				local botSyncActive = Cache.Connections["BotSyncActive"]
				if not botSyncActive then
					if hum and hum.Health > 0 then hum.Health = 0 end
				end

				task.wait(1)
				continue
			end

			Hub.SetNoclip(true)

			local plat = createFarmPlatform()
			plat.CFrame = hrp.CFrame * CFrame.new(0, -3.5, 0)

			local cam = Workspace.CurrentCamera
			if cam and cam.CameraSubject ~= hum then
				cam.CameraSubject = hum
			end

			local coins = Hub.GetCoins()

			if #coins == 0 then
				local container = Workspace:FindFirstChild("CoinContainer", true) or Workspace:FindFirstChild("Coin_Container", true)
				if not container or #container:GetChildren() == 0 then
					table.clear(CollectedCoins)
				end
				task.wait(0.5)
				continue
			end

			-------------------------------------------------------
			-- OPTIMIZED NEAREST-AGENT COORDINATION LOGIC
			-------------------------------------------------------
			local activeSquadHRPs = GetActiveSquadHRPs()

			-- Compile everyone currently competing on the map (Self + active bots)
			local allParticipants = { hrp }
			for _, otherHRP in ipairs(activeSquadHRPs) do
				table.insert(allParticipants, otherHRP)
			end

			local myExclusiveCoins = {}
			local fallbackCoins = {}

			for _, coin in ipairs(coins) do
				if coin and coin.Parent and not CollectedCoins[coin] and coin.Position.Magnitude > 10 then
					local closestParticipant = nil
					local minParticipantDist = math.huge

					-- Find which bot is currently closest to this specific coin
					for _, participant in ipairs(allParticipants) do
						local pDist = (participant.Position - coin.Position).Magnitude
						if pDist < minParticipantDist then
							minParticipantDist = pDist
							closestParticipant = participant
						end
					end

					local myDist = (hrp.Position - coin.Position).Magnitude

					if closestParticipant == hrp then
						-- We are the closest agent; prioritize this coin exclusively
						table.insert(myExclusiveCoins, { coin = coin, dist = myDist })
					else
						-- Only consider as fallback if the closest bot is still relatively far from it
						if minParticipantDist > 12 then
							table.insert(fallbackCoins, { coin = coin, dist = myDist })
						end
					end
				end
			end

			local closestCoin = nil

			-- Assign targets prioritizing exclusive zones first
			if #myExclusiveCoins > 0 then
				table.sort(myExclusiveCoins, function(a, b) return a.dist < b.dist end)
				closestCoin = myExclusiveCoins[1].coin
			elseif #fallbackCoins > 0 then
				table.sort(fallbackCoins, function(a, b) return a.dist < b.dist end)
				closestCoin = fallbackCoins[1].coin
			end
			-------------------------------------------------------

			if closestCoin and closestCoin.Parent then
				CollectedCoins[closestCoin] = true

				local targetCFrame = closestCoin.CFrame
				if Cache.Use5YOffset then
					targetCFrame = targetCFrame - Vector3.new(0, Cache.YOffset or 2, 0)
				end

				local distance = (hrp.Position - targetCFrame.Position).Magnitude
				local speed = math.clamp(Cache.TweenSpeed or 20, 10, 100)
				local duration = distance / speed

				local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
				local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
				Cache.CurrentTween = tween

				tween:Play()

				local startTime = tick()
				local checkTimer = 0

				while (tick() - startTime) < duration and closestCoin and closestCoin.Parent and hum.Health > 0 and Cache.Connections["CoinFarmActive"] and not Hub.IsPlayerInLobby(hrp) do
					if farmPlatform and farmPlatform.Parent then
						farmPlatform.CFrame = hrp.CFrame * CFrame.new(0, -3.5, 0)
					end

					local currentDist = (hrp.Position - targetCFrame.Position).Magnitude
					if currentDist <= 0.4 then
						pcall(function() tween:Cancel() end)
						break
					end

					-- Proximity Interrupt: Every 5 frames, check if a brand-new coin spawned right next to us
					checkTimer = checkTimer + 1
					if checkTimer >= 5 then
						checkTimer = 0
						if currentDist > 25 then
							local nearbyCoins = Hub.GetCoins()
							for _, nc in ipairs(nearbyCoins) do
								if nc and nc.Parent and nc ~= closestCoin and not CollectedCoins[nc] then
									local ncDist = (hrp.Position - nc.Position).Magnitude
									if ncDist < 10 then
										pcall(function() tween:Cancel() end)
										break
									end
								end
							end
						end
					end

					RunService.Heartbeat:Wait()
				end

				if Cache.CurrentTween then
					pcall(function() Cache.CurrentTween:Destroy() end)
					Cache.CurrentTween = nil
				end
				
				RunService.Heartbeat:Wait()
			end
		end

		if Cache.CurrentTween then
			pcall(function() Cache.CurrentTween:Cancel() Cache.CurrentTween:Destroy() end)
			Cache.CurrentTween = nil
		end
		destroyFarmPlatform()
		Hub.SetNoclip(false)
	end)
end

-----------------------------------
-- COIN ESP HIGHLIGHTS
-----------------------------------
function Hub.StartCoinESP(state)
	Cache.Connections["ExpandHitboxes"] = state
	if state then
		task.spawn(function()
			while Cache.Connections["ExpandHitboxes"] do
				local coins = Hub.GetCoins()
				if #coins > 0 then
					for _, coinPart in ipairs(coins) do
						if coinPart and coinPart.Parent then
							if not coinPart:FindFirstChild("DashboardBox") then
								local box = Instance.new("SelectionBox")
								box.Name = "DashboardBox"
								box.Adornee = coinPart
								box.Color3 = Hub.Theme.AccentRed
								box.LineThickness = 0.05
								box.Transparency = 0.4
								box.Parent = coinPart
							end
						end
					end
				end
				task.wait(0.3)
			end
		end)
	else
		for _, descendant in ipairs(Workspace:GetDescendants()) do
			if descendant:FindFirstChild("DashboardBox") then
				descendant.DashboardBox:Destroy()
			end
		end
	end
end

-----------------------------------
-- BOT COMMUNICATION SYNC
-----------------------------------
function Hub.StartBotSync(state)
	Cache.Connections["BotSyncActive"] = state

	if state then
		task.spawn(function()
			while Cache.Connections["BotSyncActive"] do
				task.wait(0.5)

				local publicMurd = Hub.GetPublicMurderer()

				if not publicMurd then
					Hub.HasResetThisRound = false
					Hub.WasOnMapThisRound = false
					Hub.DiedThisRound = false
					Hub.SquadAllReadyTime = nil
				end

				local char = LocalPlayer.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				local hum = char and char:FindFirstChildOfClass("Humanoid")

				if hum and hum.Health <= 0 and Hub.WasOnMapThisRound then
					Hub.DiedThisRound = true
				end

				if hum and hum.Health > 0 and hrp then
					local selfInLobby = Hub.IsPlayerInLobby(hrp)
					local selfFull = Hub.IsBagFull()

					local allSquadReady = selfInLobby or (selfFull and selfInLobby) or Hub.DiedThisRound or (hum.Health <= 0)
					local selectedCount = 0
					local readyCount = allSquadReady and 1 or 0

					for userId, isSelected in pairs(VisualSelectedBots) do
						if isSelected then
							selectedCount = selectedCount + 1
							local botPlayer = Players:GetPlayerByUserId(userId)
							if Hub.IsBotReady(botPlayer) then
								readyCount = readyCount + 1
							else
								allSquadReady = false
							end
						end
					end

					Stats.SquadReadyText = tostring(readyCount) .. "/" .. tostring(selectedCount + 1)
					Stats.AllReady = allSquadReady

					local selfRole = Hub.GetLocalPlayerRole()

					if not allSquadReady then
						Hub.SquadAllReadyTime = nil
					else
						Hub.SquadAllReadyTime = Hub.SquadAllReadyTime or tick()
						local elapsed = tick() - Hub.SquadAllReadyTime

						-- 1. Murderer resets immediately if squad is ready in lobby
						if selfRole == "MURDERER" then
							if (selfInLobby or selfFull) and not Hub.HasResetThisRound then
								Hub.HasResetThisRound = true
								hum.Health = 0
								Hub.SquadAllReadyTime = nil
							end

						-- 2. Innocent Logic
						elseif selfRole == "INNOCENT" then
							if publicMurd and not Hub.DiedThisRound then
								if elapsed >= 8 and not Hub.HasResetThisRound then
									local _, mapAlive = Hub.GetAlivePlayers()
									if #mapAlive > 0 and (selfInLobby or selfFull) then
										Hub.HasResetThisRound = true
										hum.Health = 0
										Hub.SquadAllReadyTime = nil
									end
								elseif Hub.HasResetThisRound and hum.Health > 0 then
									flingMurdererLooped(publicMurd)
								end
							end

						-- 3. Sheriff Logic
						elseif selfRole == "SHERIFF" then
							if elapsed >= 3 then
								local totalAlive, _ = Hub.GetAlivePlayers()

								if #totalAlive <= 2 and publicMurd and table.find(totalAlive, publicMurd) then
									hum.Health = 0
									Hub.SquadAllReadyTime = nil
								elseif publicMurd then
									shootMurdererLooped(publicMurd)
								end
							end
						end
					end
				end
			end
		end)
	end
end

print("[MM2 Hub] FarmingAndBots.lua loaded successfully!")
