--!nocheck
-----------------------------------
-- STATUS CLIENT & HEARTBEAT MODULE
-----------------------------------
local Hub = getgenv().Hub or {}
getgenv().Hub = Hub

local Services = {
	Players = game:GetService("Players"),
	HttpService = game:GetService("HttpService")
}

local LocalPlayer = Services.Players.LocalPlayer
local API_URL_1 = "http://127.0.0.1:8080/api"
local API_URL_2 = "http://localhost:8080/api"

local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)

Hub.SessionCoins = Hub.SessionCoins or 0
Hub.BotStatus = Hub.BotStatus or "FARMING"

local lastBagValue = 0

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

-- Monitor real-time coin bag increases during active rounds
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

-- Send Periodic Heartbeats to Python Server
task.spawn(function()
	task.wait(2)
	print("[StatusClient] Heartbeat service active for: " .. tostring(LocalPlayer.Name))

	while task.wait(4) do
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
			end
		end
	end
end)

print("[MM2 Hub] StatusClient.lua loaded successfully!")
