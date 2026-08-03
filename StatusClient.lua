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

-- Universal Executor Request Function
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)

-- Session Coins starts at 0 for EVERY new batch instance
Hub.SessionCoins = 0
Hub.BotStatus = "FARMING"

local lastCoinValue = nil

local function getPlayerCoinAmount()
	-- 1. Check leaderstats (MM2 Coins value)
	local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins") or leaderstats:FindFirstChild("Coin") or leaderstats:FindFirstChild("Credits")
		if coins then return coins.Value end
	end
	
	-- 2. Check PlayerGui Coin Bag TextLabel
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if playerGui then
		local mainGui = playerGui:FindFirstChild("MainGUI")
		if mainGui then
			for _, descendant in ipairs(mainGui:GetDescendants()) do
				if descendant:IsA("TextLabel") and (descendant.Name:lower():find("coin") or descendant.Parent.Name:lower():find("coin")) then
					local num = tonumber(descendant.Text:match("%d+"))
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
				if delta > 0 then
					Hub.SessionCoins = Hub.SessionCoins + delta
					print("[StatusClient] + " .. tostring(delta) .. " coin(s) collected! Session Total: " .. tostring(Hub.SessionCoins) .. "c")
				end
			end
			lastCoinValue = currentAmount
		end
	end
end)

-- Send Periodic Heartbeats to Python Server with Debug Output
task.spawn(function()
	task.wait(2) -- Wait for player to load into server
	print("[StatusClient] Heartbeat service initialized for: " .. tostring(LocalPlayer.Name))

	while task.wait(4) do
		if not httpRequest then
			warn("[StatusClient ERROR] No HTTP request function supported by executor!")
			break
		end

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
			local result = nil
			
			-- Try primary API URL (127.0.0.1)
			local success, err = pcall(function()
				result = httpRequest({
					Url = API_URL_1,
					Method = "POST",
					Headers = {
						["Content-Type"] = "application/json"
					},
					Body = jsonString
				})
			end)

			-- Fallback to localhost if 127.0.0.1 failed
			if not success or not (result and (result.StatusCode == 200 or result.StatusMessage == "OK")) then
				pcall(function()
					result = httpRequest({
						Url = API_URL_2,
						Method = "POST",
						Headers = {
							["Content-Type"] = "application/json"
						},
						Body = jsonString
					})
				end)
			end

			if result and (result.StatusCode == 200 or result.StatusMessage == "OK") then
				print("[StatusClient SUCCESS] Sent Heartbeat -> User: " .. LocalPlayer.Name .. " | Coins: " .. tostring(Hub.SessionCoins) .. "c | Status: " .. Hub.BotStatus)
			else
				warn("[StatusClient WARNING] Heartbeat HTTP failed or refused by Python server! Response: " .. tostring(result and result.StatusCode or "No Response"))
			end
		else
			warn("[StatusClient ERROR] JSON encoding failed!")
		end
	end
end)

print("[MM2 Hub] StatusClient.lua loaded successfully!")
