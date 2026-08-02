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
-- SMOOTH TWEENING SHERIFF SHOOTER
-----------------------------------
local isShootingLoopActive = false
local function shootMurdererLooped(murdPlayer)
	if isShootingLoopActive or not murdPlayer then return end
	isShootingLoopActive = true

	task.spawn(function()
		while Cache.Connections["BotSyncActive"] do
			if Hub.GetLocalPlayerRole and Hub.GetLocalPlayerRole() ~= "SHERIFF" then
				break
			end

			local char = LocalPlayer.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			
			local murdChar = murdPlayer and murdPlayer.Character
			local murdHRP = murdChar and murdChar:FindFirstChild("HumanoidRootPart")
			local murdHum = murdChar and murdChar:FindFirstChildOfClass("Humanoid")

			if not hrp or not murdHRP or not hum or hum.Health <= 0 or not murdHum or murdHum.Health <= 0 then 
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
					for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
						if item:IsA("Tool") and (item.Name:lower():find("gun") or item.Name:lower():find("revolver")) then
							gun = item
							break
						end
					end
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
					for _, v in ipairs(gun:GetDescendants()) do
						if v:IsA("RemoteEvent") then
							pcall(function() v:FireServer(murdHRP.Position, murdHRP.Position, murdHRP, murdHRP.Position) end)
							pcall(function() v:FireServer(murdHRP.Position) end)
						end
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
-- COIN FARM TOGGLE & LOOP
-----------------------------------
function Hub.StartCoinFarm(state)
	Cache.Connections["CoinFarmActive"] = state

	if not state then
		if Cache.CurrentTween then
			pcall(function() Cache.CurrentTween:Cancel() Cache.CurrentTween:Destroy() end)
			Cache.CurrentTween = nil
		end
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
				Hub.SetNoclip(false)
				task.wait(0.5)
				continue
			end

			if Hub.IsPlayerInLobby(hrp) then
				if Cache.CurrentTween then
					pcall(function() Cache.CurrentTween:Cancel() Cache.CurrentTween:Destroy() end)
					Cache.CurrentTween = nil
				end
				Hub.SetNoclip(false)
				task.wait(0.5)
				continue
			end

			local full = Hub.IsBagFull()
			LocalPlayer:SetAttribute("BagFull", full)
			
			if full then
				if Cache.CurrentTween then
					pcall(function() Cache.CurrentTween:Cancel() Cache.CurrentTween:Destroy() end)
					Cache.CurrentTween = nil
				end
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

			local coins = Hub.GetCoins()

			if #coins == 0 then
				local container = Workspace:FindFirstChild("CoinContainer", true) or Workspace:FindFirstChild("Coin_Container", true)
				if not container or #container:GetChildren() == 0 then
					table.clear(CollectedCoins)
				end
				task.wait(0.5)
				continue
			end

			local closestCoin = nil
			local shortestDist = math.huge

			-- Ignore coins that were already marked as collected so we don't re-target lingering parts
			for _, coin in ipairs(coins) do
				if coin and coin.Parent and not CollectedCoins[coin] then
					local dist = (hrp.Position - coin.Position).Magnitude
					if dist < shortestDist then
						shortestDist = dist
						closestCoin = coin
					end
				end
			end

			if closestCoin and closestCoin.Parent then
				-- IMMEDIATELY mark coin as collected so the next loop iteration instantly ignores it
				CollectedCoins[closestCoin] = true

				local targetCFrame = closestCoin.CFrame
				if Cache.Use5YOffset then
					targetCFrame = targetCFrame - Vector3.new(0, Cache.YOffset or 2, 0)
				end

				local distance = (hrp.Position - targetCFrame.Position).Magnitude
				local speed = math.clamp(Cache.TweenSpeed or 20, 10, 100)
				local duration = math.max(distance / speed, 0.12)

				local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
				local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
				Cache.CurrentTween = tween

				tween:Play()

				local startTime = tick()
				while (tick() - startTime) < duration and closestCoin and closestCoin.Parent and hum.Health > 0 and Cache.Connections["CoinFarmActive"] and not Hub.IsPlayerInLobby(hrp) do
					if (hrp.Position - targetCFrame.Position).Magnitude <= 0.8 then
						pcall(function() tween:Cancel() end)
						break
					end

					RunService.Heartbeat:Wait()
				end

				if Cache.CurrentTween then
					pcall(function() Cache.CurrentTween:Destroy() end)
					Cache.CurrentTween = nil
				end
				task.wait(0.08)
			end
		end

		if Cache.CurrentTween then
			pcall(function() Cache.CurrentTween:Cancel() Cache.CurrentTween:Destroy() end)
			Cache.CurrentTween = nil
		end
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

				local char = LocalPlayer.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				local hum = char and char:FindFirstChildOfClass("Humanoid")

				if hum and hum.Health > 0 and hrp then
					local selfInLobby = Hub.IsPlayerInLobby(hrp)
					local selfFull = Hub.IsBagFull()

					local allSquadReady = selfInLobby or (selfFull and selfInLobby) or (hum.Health <= 0)
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
					local isRoundActive = Hub.IsRoundActive and Hub.IsRoundActive() or false

					if not allSquadReady then
						Hub.SquadAllReadyTime = nil
					else
						Hub.SquadAllReadyTime = Hub.SquadAllReadyTime or tick()
						local elapsed = tick() - Hub.SquadAllReadyTime

						if selfRole == "MURDERER" then
							if isRoundActive and (selfInLobby or selfFull) and not Hub.HasResetThisRound then
								Hub.HasResetThisRound = true
								hum.Health = 0
								Hub.SquadAllReadyTime = nil
							end

						elseif selfRole == "INNOCENT" then
							-- Prevent auto-resetting every 8 seconds while waiting in the lobby
							if isRoundActive and elapsed >= 8 and not Hub.HasResetThisRound then
								local _, mapAlive = Hub.GetAlivePlayers()
								if #mapAlive > 0 and (selfInLobby or selfFull) then
									Hub.HasResetThisRound = true
									hum.Health = 0
									Hub.SquadAllReadyTime = nil
								else
									Hub.SquadAllReadyTime = nil
								end
							elseif not isRoundActive then
								Hub.SquadAllReadyTime = nil
							end

						elseif selfRole == "SHERIFF" then
							if elapsed >= 3 then
								local publicMurd = Hub.GetPublicMurderer()
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
