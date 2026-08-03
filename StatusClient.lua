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

-- Initialize session coins to 0 on launch
Hub.SessionCoins = Hub.SessionCoins or 0
Hub.BotStatus = Hub.BotStatus or "FARMING"

-- Send Periodic Heartbeats to Python Server
task.spawn(function()
	task.wait(2) -- Wait for player to load into server
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
			else
				warn("[StatusClient WARNING] Heartbeat HTTP failed/refused by Python server!")
			end
		end
	end
end)

print("[MM2 Hub] StatusClient.lua loaded successfully!")
