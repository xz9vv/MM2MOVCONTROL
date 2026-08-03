--!nocheck
-----------------------------------
-- STATUS CLIENT & HEARTBEAT MODULE
-----------------------------------
local Hub = getgenv().Hub or {}
getgenv().Hub = Hub

local Services = {
	Players = game:GetService("Players"),
	HttpService = game:GetService("HttpService"),
	GuiService = game:GetService("GuiService"),
	CoreGui = game:GetService("CoreGui")
}

local LocalPlayer = Services.Players.LocalPlayer
local API_URL_1 = "http://127.0.0.1:8080/api"
local API_URL_2 = "http://localhost:8080/api"

local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)

Hub.SessionCoins = Hub.SessionCoins or 0
Hub.BotStatus = Hub.BotStatus or "FARMING"
Hub.AutoConfigLoaded = false

local lastBagValue = 0
local serverJoinTime = tick()
local qualityCheckDone = false

-- Check if player was kicked (Error 267, 277, Disconnect Prompt)
local function isPlayerKicked()
	if not LocalPlayer or not LocalPlayer.Parent then
		return true
	end

	local success, errorCode = pcall(function()
		return Services.GuiService:GetErrorCode()
	end)
	if success and errorCode and errorCode.Value ~= 0 then
		return true
	end

	local promptOverlay = Services.CoreGui:FindFirstChild("RobloxPromptGui") and Services.CoreGui.RobloxPromptGui:FindFirstChild("promptOverlay")
	if promptOverlay and promptOverlay:FindFirstChild("ErrorPrompt") then
		return true
	end

	return false
end

-- Exact DarkDex MM2 Bag TextLabel Reader
local function getExactBagCoinCount()
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if playerGui then
		local mainGui = playerGui:FindFirstChild("MainGUI")
		if mainGui then
			local gameFrame = mainGui:FindFirstChild("Game")
			if gameFrame then
				local coinBags = gameFrame:FindFirstChild("CoinBags")
				if coinBags then
					local container = coinBags:FindFirstChild("Container")
					if container then
						local coin = container:FindFirstChild("Coin")
						if coin then
							local currencyFrame = coin:FindFirstChild("CurrencyFrame")
							if currencyFrame then
								local icon = currencyFrame:FindFirstChild("Icon")
								if icon then
									local coinsLabel = icon:FindFirstChild("Coins")
									if coinsLabel and coinsLabel:IsA("TextLabel") then
										local num = tonumber(coinsLabel.Text:match("%d+"))
										if num then return num end
									end
								end
							end
						end
					end
				end
			end
		end
	end
	return 0
end

-- Monitor real-time coin bag increases
task.spawn(function()
	while task.wait(0.2) do
		local currentBag = getExactBagCoinCount()
		if currentBag > lastBagValue then
			local gained = currentBag - lastBagValue
			Hub.SessionCoins = Hub.SessionCoins + gained
			print("[StatusClient] Bag +" .. tostring(gained) .. "c | Session Total: " .. tostring(Hub.SessionCoins) .. "c")
		end
		lastBagValue = currentBag
	end
end)

-- Send Periodic Heartbeats, Execute 2-Min Quality Check, & Auto-Shutdown on Kick
task.spawn(function()
	task.wait(2)
	print("[StatusClient] Heartbeat service active for: " .. tostring(LocalPlayer.Name))

	while task.wait(4) do
		-- KICK/DISCONNECT DETECTION
		if isPlayerKicked() then
			warn("[StatusClient] KICK/DISCONNECT DETECTED! Shutting down window...")
			Hub.BotStatus = "DISCONNECTED"
			
			local payload = {
				AccountUsername = LocalPlayer.Name,
				CurrentCoins = Hub.SessionCoins or 0,
				Status = "DISCONNECTED"
			}
			
			pcall(function()
				local jsonString = Services.HttpService:JSONEncode(payload)
				httpRequest({
					Url = API_URL_1,
					Method = "POST",
					Headers = { ["Content-Type"] = "application/json" },
					Body = jsonString
				})
			end)
			
			task.wait(0.5)
			pcall(function() game:Shutdown() end)
			break
		end

		-- ONE-TIME 2-MINUTE SERVER QUALITY CHECK
		local elapsedServerTime = tick() - serverJoinTime
		if elapsedServerTime >= 120 and not qualityCheckDone then
			qualityCheckDone = true
			
			local nonBotCount = 0
			for _, p in ipairs(Services.Players:GetPlayers()) do
				if p ~= LocalPlayer then
					local isBot = false
					if Hub.VisualSelectedBots and Hub.VisualSelectedBots[p.UserId] then
						isBot = true
					end
					if not isBot then
						nonBotCount = nonBotCount + 1
					end
				end
			end
			
			if nonBotCount > 2 then
				print("[StatusClient] 2-Min Quality Check FAILED! (" .. tostring(nonBotCount) .. " public players). Triggering Server Hop...")
				Hub.BotStatus = "SERVER_INCOMPATIBLE"
				
				local payload = {
					AccountUsername = LocalPlayer.Name,
					CurrentCoins = Hub.SessionCoins or 0,
					Status = "SERVER_INCOMPATIBLE"
				}
				
				pcall(function()
					local jsonString = Services.HttpService:JSONEncode(payload)
					httpRequest({
						Url = API_URL_1,
						Method = "POST",
						Headers = { ["Content-Type"] = "application/json" },
						Body = jsonString
					})
				end)
				
				task.wait(0.5)
				pcall(function() game:Shutdown() end)
				break
			else
				print("[StatusClient] 2-Min Quality Check PASSED! Server is clean (" .. tostring(nonBotCount) .. " public players). Farming until 1,000 coins!")
			end
		end

		if not httpRequest then
			warn("[StatusClient ERROR] No HTTP request function supported by executor!")
			break
		end

		if (Hub.SessionCoins or 0) >= 1000 then
			Hub.BotStatus = "COMPLETED"
		end

		local payload = {
			AccountUsername = LocalPlayer.Name,
			CurrentCoins = Hub.SessionCoins or 0,
			Status = Hub.BotStatus
		}

		local jsonSuccess, jsonString = pcall(function()
			return Services.HttpService:JSONEncode(payload)
		end)

		if jsonSuccess then
			local result = nil
			
			local success, _ = pcall(function()
				result = httpRequest({
					Url = API_URL_1,
					Method = "POST",
					Headers = { ["Content-Type"] = "application/json" },
					Body = jsonString
				})
			end)

			if not success or not (result and (result.StatusCode == 200 or result.StatusMessage == "OK")) then
				pcall(function()
					result = httpRequest({
						Url = API_URL_2,
						Method = "POST",
						Headers = { ["Content-Type"] = "application/json" },
						Body = jsonString
					})
				end)
			end

			if result and (result.StatusCode == 200 or result.StatusMessage == "OK") then
				print("[StatusClient SUCCESS] Sent Heartbeat -> User: " .. LocalPlayer.Name .. " | Coins: " .. tostring(Hub.SessionCoins or 0) .. "c | Status: " .. tostring(Hub.BotStatus))
				
				if result.Body and not Hub.AutoConfigLoaded then
					local parseOk, resData = pcall(function()
						return Services.HttpService:JSONEncode(result.Body)
					end)
					if parseOk and resData and resData.active_config then
						print("[StatusClient] Successfully pulled Active Config from Python server!")
						Hub.AutoConfigLoaded = true
						if Hub.LoadConfigFromTable then
							pcall(function() Hub.LoadConfigFromTable(resData.active_config) end)
						end
					end
				end
			end
		end
	end
end)

print("[MM2 Hub] StatusClient.lua loaded successfully!")
