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
local API_URL = "http://127.0.0.1:8080/api"

-- Universal Executor Request Function (Xeno, Synapse, Fluxus, etc.)
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)

-- Session Coins starts at 0 for EVERY new batch instance
Hub.SessionCoins = 0
Hub.BotStatus = "FARMING"

local lastCoinValue = nil

local function getPlayerCoinAmount()
	-- Check leaderstats
	local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins") or leaderstats:FindFirstChild("Coin")
		if coins then return coins.Value end
	end
	
	-- Fallback to PlayerGui Coin Bag text
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if playerGui then
		local mainGui = playerGui:FindFirstChild("MainGUI")
		if mainGui then
			local coinBag = mainGui:FindFirstChild("Game", true)
			if coinBag then
				local amountText = coinBag:FindFirstChild("CoinBag", true) or coinBag:FindFirstChild("Amount", true)
				if amountText and amountText:IsA("TextLabel") then
					local num = tonumber(amountText.Text:match("%d+"))
					if num then return num end
				end
			end
		end
	end
	
	return nil
end

-- Monitor coin gains in real time during this session ONLY
task.spawn(function()
	while task.wait(0.3) do
		local currentAmount = getPlayerCoinAmount()
		if currentAmount then
			if lastCoinValue ~= nil then
				local delta = currentAmount - lastCoinValue
				-- Only count positive coin gains during this session
				if delta > 0 then
					Hub.SessionCoins = Hub.SessionCoins + delta
				end
			end
			lastCoinValue = currentAmount
		end
	end
end)

-- Send Periodic Heartbeats to Python Server (http://127.0.0.1:8080/api)
task.spawn(function()
	while task.wait(5) do
		if not httpRequest then
			warn("[StatusClient] No supported HTTP request function found on this executor!")
			break
		end

		-- Mark batch completed once 1,000 coins are collected in this session
		if Hub.SessionCoins >= 1000 then
			Hub.BotStatus = "COMPLETED"
		end

		local payload = {
			AccountUsername = LocalPlayer.Name,
			CurrentCoins = Hub.SessionCoins,
			Status = Hub.BotStatus
		}

		local jsonSuccess, jsonString = pcall(function()
			return Services.HttpService:JSONEncode(payload)
		end)

		if jsonSuccess then
			pcall(function()
				httpRequest({
					Url = API_URL,
					Method = "POST",
					Headers = {
						["Content-Type"] = "application/json"
					},
					Body = jsonString
				})
			end)
		end
	end
end)

print("[MM2 Hub] StatusClient.lua loaded successfully!")
